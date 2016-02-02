#!/bin/sh

echo "SSH_Private_Key_Login 2.0 by Andreas Prang"
echo ""

default_server_user="root"
default_public_key_path=""

function installNewKeys {
    read -p "Please enter target ssh server (FQN or IP w/o port!): " server_name
    read -p "Please enter target ssh server port (22): " server_port
    server_port=${server_port:-22}

    read -p "Please enter user on target ssh server ($default_server_user): " server_user
    server_user=${server_user:-$default_server_user}

    read -p "Please enter a local path where to save keys (~/Documents/myKeys/$server_name""_$server_port/): " local_key_path
    local_key_path=${local_key_path:-~/Documents/myKeys/$server_name"_$server_port"/}

    echo "-----------------------------------------------------------------"

    # check for slash at the end
    if [ "${local_key_path:LEN - 1}" != "/" ]; then
      echo "Adding trailing slash"
      local_key_path=$local_key_path"/"
    fi

    echo "Creating Path "$local_key_path
    mkdir -p $local_key_path

    echo "Creating Certificates"
    ssh-keygen -t dsa -f $local_key_path$server_name

    echo "-----------------------------------------------------------------"
    echo "Copy public key to "$server_user"@"$server_name":"$server_port
    scp -P $server_port $local_key_path""$server_name".pub" $server_user@""$server_name":~/"

    echo "-----------------------------------------------------------------"

    echo "Setup key on "$server_user"@"$server_name":"$server_port
    ssh -p $server_port $server_user@$server_name "mkdir -p ~/.ssh/;touch ~/.ssh/authorized_keys2;cat ~/"$server_name".pub >> ~/.ssh/authorized_keys2;rm ~/"$server_name".pub"

    echo "Add private key to known hosts"
    mkdir -p ~/.ssh
    touch ~/.ssh/known_hosts
    cat $local_key_path""$server_name >> ~/.ssh/known_hosts

    echo "Register private key on local machine"
    ssh-add $local_key_path""$server_name
}

function installExistingKey {
    read -p "Please enter target ssh server (FQN or IP w/o port!): " server_name
    read -p "Please enter target ssh server port (22): " server_port
    read -p "Please enter path to public key file ($public_key_path):" public_key_path
    public_key_path=${public_key_path:-"$default_public_key_path"}
    public_key_path=$(find $public_key_path)
    ! [ -e "$public_key_path" ] && echo "Public key not found! Do not use paths starting with: '~'" && exit 0
    default_public_key_path="$public_key_path"

    server_port=${server_port:-22}
    public_key_file=$(basename $public_key_path)

    read -p "Please enter user on target ssh server ($default_server_user): " server_user
    server_user=${server_user:-$default_server_user}
    default_server_user=$server_user

    echo "-----------------------------------------------------------------"
    echo "Copy public key to "$server_user"@"$server_name":"$server_port
    scp -P $server_port $public_key_path $server_user@""$server_name":~/"

    echo "-----------------------------------------------------------------"

    echo "Setup key on "$server_user"@"$server_name":"$server_port
    ssh -p $server_port $server_user@$server_name "mkdir -p ~/.ssh/;touch ~/.ssh/authorized_keys2;cat ~/"$public_key_file" >> ~/.ssh/authorized_keys2;rm ~/"$public_key_file
    echo "Done."

    echo "-----------------------------------------------------------------"
}

function registerKey {
  read -p "Please enter path to private key file:" private_key_path
  private_key_path="${private_key_path%????}"
  if [ ! -f $private_key_path ]; then
    echo "Private key not found!"
    exit 1
  fi
  mkdir -p ~/.ssh
  touch ~/.ssh/known_hosts
  cat $private_key_path >> ~/.ssh/known_hosts

  echo "Register private key on local machine"
  ssh-add $private_key_path
}

while true; do
  echo "1) Install new public/private ssh key"
  echo "2) Install existing public key on remote server"
  echo "3) Register private key locally"
  echo "x) Exit"
  read -p ": " yn
  case $yn in
    [1]* ) installNewKeys;;
    [2]* ) installExistingKey;;
    [3]* ) registerKey;;
    * ) echo "Bye..."; break;;
  esac
done

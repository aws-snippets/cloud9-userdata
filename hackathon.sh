#!/bin/bash

# Yum Update
sudo yum update -y

# Insert custom commands below:
echo "$1"
USERS=("User1" "User2" "User3")
userList=""

for userId in "${USERS[@]}" ; do 
    #echo $userId    
    randomPwd=$(aws secretsmanager get-random-password \
    --require-each-included-type \
    --password-length 20 \
    --include-space \
    --output text)

    #echo $randomPwd    
    userList="$userList"$'\n'"Username: $userId, Password: $randomPwd"
    user=`aws iam create-user --user-name $userId`  
    profile=$(aws iam create-login-profile --user-name $userId --password $randomPwd --password-reset-required)
done



if [ "$ENVIRONMENT_PATH" == "/home/ec2-user/environment" ] && [ ! -f "$ENVIRONMENT_PATH"/README.md ]; then
    cat <<'EOF' >> "$ENVIRONMENT_PATH"/README.md
         ___        ______     ____ _                 _  ___
        / \ \      / / ___|   / ___| | ___  _   _  __| |/ _ \
       / _ \ \ /\ / /\___ \  | |   | |/ _ \| | | |/ _` | (_) |
      / ___ \ V  V /  ___) | | |___| | (_) | |_| | (_| |\__, |
     /_/   \_\_/\_/  |____/   \____|_|\___/ \__,_|\__,_|  /_/
 -----------------------------------------------------------------


Hi there! Welcome to AWS Cloud9!

To get started, create some files, play with the terminal,
or visit https://docs.aws.amazon.com/console/cloud9/ for our documentation.

Following user accounts have been created:
echo "$userList"

Happy coding!

EOF

    chown "$UNIX_USER":"$UNIX_GROUP" "$UNIX_USER_HOME"/environment/README.md
fi
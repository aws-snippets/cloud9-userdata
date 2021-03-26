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

echo "$userList"

#wget https://raw.githubusercontent.com/aws-snippets/cloud9-userdata/main/user-setup.sh
#sh user-setup.sh -e nfrgean -u user1

while getopts ":e:u:" opt; do
  case $opt in
    e) environmentId="$OPTARG"
    ;;
    u) users="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo $environmentId
echo $users

environmentId='877f86c3bb80418aabc9956580436e9a'
users=('User1')
groupName='HackathonUsers'
groupPolicy='arn:aws:iam::aws:policy/AdministratorAccess'

function createRepo() {
    sam init --runtime python3.7 --dependency-manager pip --app-template hello-world --name sam-app --no-interactive
    cd sam-app
    repoUrl=`aws codecommit create-repository --repository-name MyDemoRepo --repository-description "My demonstration repository" --query 'repositoryMetadata.cloneUrlHttp' | sed -e 's/\/.*\///g' | tr -d '"'`
    echo $repoUrl
    git config --global init.defaultBranch main
    git init
    git add .
    git commit –m "Initial commit"
    git push $repoUrl --all
}

function createUsers() {
    userList=""    

    aws iam create-group \
    --group-name $groupName \
    --query 'Group.GroupName'

    aws iam attach-group-policy \
    --policy-arn $groupPolicy \
    --group-name $groupName

    echo "Created user group - HackathonUsers"

    for userName in "${users[@]}" ; do 
        #echo $userId    
        randomPwd=$(aws secretsmanager get-random-password \
        --require-each-included-type \
        --password-length 20 \
        --include-space \
        --output text)

        #echo $randomPwd    
        userList="$userList"$'\n'"Username: $userName, Password: $randomPwd"
        
        userArn=`aws iam create-user \
        --user-name $userName \
        --query 'User.Arn' | sed -e 's/\/.*\///g' | tr -d '"'`
        #userArns+=$user.User.Arn      
        #echo $userArn
        
        aws iam wait user-exists \
        --user-name $userName
        
        aws iam create-login-profile \
        --user-name $userName \
        --password $randomPwd \
        --password-reset-required \
        --query "LoginProfile.UserName"
        
        aws iam add-user-to-group \
        --user-name $userName \
        --group-name $groupName

        aws cloud9 create-environment-membership --environment-id $environmentId --user-arn $userArn --permissions read-write
    done

    echo "Following users have been created and added to $groupName group."
    echo "$userList"
}

function cleanUp() {
    echo "Starting cleanup..."
    # for userArn in "${userArns[@]}" ; do 
    #     aws cloud9 delete-environment-membership \
    #     --environment-id $environmentId \
    #     --user-arn $userArn
    # done

    for userName in "${users[@]}" ; do 
        aws iam remove-user-from-group \
        --user-name $userName \
        --group-name $groupName

        aws iam delete-login-profile \
        --user-name $userName 

        aws iam delete-user \
        --user-name $userName 
        echo "Succesfully deleted $userName"
    done

    aws iam detach-group-policy \
    --group-name $groupName \
    --policy-arn $groupPolicy

    aws iam delete-group \
    --group-name $groupName
    echo "Succesfully deleted $groupName user group"

    echo "Cleanup complete."
}

#createUsers
cleanUp


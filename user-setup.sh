#wget https://raw.githubusercontent.com/aws-snippets/cloud9-userdata/main/user-setup.sh
#
#USAGE: 
#STEP 1: Execute following command within Cloud9 terminal to retrieve envronment id
# aws cloud9 list-environments
#STEP 2: Execute following command by providing appropriate parameters -e ENVIRONMENTID -u USERNAME1,USERNAME2,USeRNAME3 -r REPONAME 
# sh user-setup.sh -e 877f86c3bb80418aabc9956580436e9a -u User1,User2 -r sam-app


while getopts ":e:u:r" opt; do
  case $opt in
    e) environmentId="$OPTARG"
    ;;
    u) users="$OPTARG"
    ;;
    r) repo="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo $environmentId
echo $users
echo $repo

#environmentId='877f86c3bb80418aabc9956580436e9a'
#users=('User1')
repo='sam-app'
groupName='HackathonUsers'
groupPolicy='arn:aws:iam::aws:policy/AdministratorAccess'

function createRepo() {
    sam init  --no-interactive --runtime python3.7 --dependency-manager pip --app-template hello-world --name $repo
    cd sam-app
    repoUrl=`aws codecommit create-repository --repository-name $repo --repository-description "My demonstration repository" --query 'repositoryMetadata.cloneUrlHttp' | tr -d '"'`
    echo $repoUrl
    git config --global init.defaultBranch main
    git init
    git add .
    git commit -m "Initial commit"
    git push $repoUrl --all
    echo "Succesfully created CodeCommit repo with sample SAM Lambda application"
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

        #Loop until counter is 3
        counter=1
        while [[ $counter -le 3 ]] ; do
                aws cloud9 create-environment-membership --environment-id $environmentId --user-arn $userArn --permissions read-write && break
                sleep 3
                ((counter++))
                echo "Retrying..."
        done
        
    done

    echo "Following users have been created and added to $groupName group."
    echo "$userList"
    createRepo
}

function cleanUp() {
    echo "Starting cleanup..."
    # for userArn in "${userArns[@]}" ; do 
    #     aws cloud9 delete-environment-membership \
    #     --environment-id $environmentId \
    #     --user-arn $userArn
    # done
    
    aws codecommit delete-repository --repository-name $repo
    echo "Succesfully deleted repo: $repo"
    
    rm -rf $repo

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
#cleanUp

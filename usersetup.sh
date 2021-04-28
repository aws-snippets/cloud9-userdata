#USAGE: 
#STEP 1: Execute following command within Cloud9 terminal to retrieve envronment id
# aws cloud9 list-environments
#STEP 2: Execute following command by providing appropriate parameters: -e ENVIRONMENTID -u USERNAME1,USERNAME2,USeRNAME3 -r REPONAME 
# sh usersetup.sh -e 877f86c3bb80418aabc9956580436e9a -u User1,User2 -r sam-app


while getopts ":e:u:r:" opt; do
  case $opt in
    e) environmentId="$OPTARG" ;;
    u) users="$OPTARG" ;;
    r) repo="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

IFS=',' read -ra userNames <<< "$users"
groupName='HackathonUsers'
groupPolicy='arn:aws:iam::aws:policy/AdministratorAccess'

function createUsers() {
    userList=""    

    aws iam create-group \
    --group-name $groupName \
    --query 'Group.GroupName'

    aws iam attach-group-policy \
    --policy-arn $groupPolicy \
    --group-name $groupName

    printf "Created user group - HackathonUsers\n"

    for userName in "${userNames[@]}" ; do 
        
        randomPwd=$(aws secretsmanager get-random-password \
        --require-each-included-type \
        --password-length 20 \
        --include-space \
        --output text)
    
        userList="$userList"$'\n'"Username: $userName, Password: $randomPwd"
        
        userArn=`aws iam create-user \
        --user-name $userName \
        --query 'User.Arn' | sed -e 's/\/.*\///g' | tr -d '"'`

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

        counter=1
        while [[ $counter -le 5 ]] ; do
                aws cloud9 create-environment-membership --environment-id $environmentId --user-arn $userArn --permissions read-write && break
                sleep 3
                ((counter++))
                printf "Retrying...\n"
        done
        
    done

    echo "Following users have been created and added to $groupName group.\n"
    echo "$userList\n"
    
}


createUsers

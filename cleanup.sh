#USAGE: 
#STEP 1: Execute following command within Cloud9 terminal to retrieve envronment id
# aws cloud9 list-environments
#STEP 2: Execute following command by providing appropriate parameters: -e ENVIRONMENTID -u USERNAME1,USERNAME2,USERNAME3 
# sh cleanup.sh -e 877f86c3bb80418aabc9956580436e9a -u User1,User2


while getopts ":e:u:" opt; do
  case $opt in
    e) environmentId="$OPTARG" ;;
    u) users="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

IFS=',' read -ra userNames <<< "$users"
groupName='HackathonUsers'
groupPolicy='arn:aws:iam::aws:policy/AdministratorAccess'


function cleanUp() {
    printf "Starting cleanup...\n"

    for userName in "${userNames[@]}" ; do 
        userArn=$(aws iam get-user \
        --user-name $userName \
        --query 'User.Arn' | tr -d '"')
        
        aws cloud9 delete-environment-membership \
        --environment-id $environmentId --user-arn $userArn
    
        aws iam remove-user-from-group \
        --user-name $userName \
        --group-name $groupName

        aws iam delete-login-profile \
        --user-name $userName 

        aws iam delete-user \
        --user-name $userName 
        printf "Succesfully deleted $userName\n"
    done

    aws iam detach-group-policy \
    --group-name $groupName \
    --policy-arn $groupPolicy

    aws iam delete-group \
    --group-name $groupName
    printf "Succesfully deleted $groupName user group\n"

    printf "Cleanup complete.\n"
}

cleanUp

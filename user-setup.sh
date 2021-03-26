sudo yum update
wget https://github.com/dotnet/core/files/2186067/openssl-libs-ami.spec.txt
rpmbuild --bb openssl-libs-ami.spec.txt
sudo rpm -i /usr/src/rpm/RPMS/x86_64/openssl-libs-1.0.0-0.x86_64.rpm
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install dotnet-sdk-3.1 zsh
sudo passwd ec2-user
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
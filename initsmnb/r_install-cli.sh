#!/bin/bash

set -euo pipefail

source ~/.bashrc

FLAVOR=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f 2)
grep '^max_connections=' /etc/yum.conf &> /dev/null || echo "max_connections=10" | sudo tee -a /etc/yum.conf

# Lots of problem, from wrong .repo content to broken selinux-container
sudo rm /etc/yum.repos.d/docker-ce.repo || true

sudo amazon-linux-extras install -y epel
sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/cyqsimon/el-rust-pkgs/repo/epel-7/cyqsimon-el-rust-pkgs-epel-7.repo
#sudo yum update -y  # Disable. It's slow to update 100+ SageMaker-provided packages.
sudo yum install -y htop tree fio dstat dos2unix tig ncdu ripgrep bat git-delta inxi mediainfo git-lfs nvme-cli aria2
echo "alias ncdu='ncdu --color dark'" | sudo tee /etc/profile.d/initsmnb-cli.sh
echo 'export DSTAT_OPTS="-cdngym"' | sudo tee -a /etc/profile.d/initsmnb-cli.sh

# moreutils: The command sponge allows us to read and write to the same file (cat a.txt|sponge a.txt)
sudo yum groupinstall "Development Tools" -y
sudo yum -y install jq gettext bash-completion moreutils openssl zsh xsel xclip amazon-efs-utils nc telnet mtr traceroute netcat 
# sudo yum -y install siege fio ioping dos2unix

if [ ! -f $CUSTOM_DIR/bin/yq ]; then
  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O $CUSTOM_DIR/bin/yq
  chmod +x $CUSTOM_DIR/bin/yq
fi

# This nbdime is broken. It crashes with ModuleNotFoundError: jsonschema.protocols.
rm ~/anaconda3/bin/nb{diff,diff-web,dime,merge,merge-web,show} ~/anaconda3/bin/git-nb* || true
hash -r

# Use the good working nbdime
ln -s ~/anaconda3/envs/JupyterSystemEnv/bin/nb{diff,diff-web,dime,merge,merge-web,show} ~/.local/bin/ || true
ln -s ~/anaconda3/envs/JupyterSystemEnv/bin/git-nb* ~/.local/bin/ || true
~/.local/bin/nbdime config-git --enable --global

# pre-commit cache survives reboot (NOTE: can also set $PRE_COMMIT_HOME)
mkdir -p ~/SageMaker/.initsmnb.d/.pre-commit.cache
ln -s ~/SageMaker/.initsmnb.d/.pre-commit.cache ~/.cache/pre-commit || true

# Catch-up with awscliv2 which has nearly weekly releases.
aria2c -x5 --dir /tmp -o awscli2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
cd /tmp && unzip -o -q /tmp/awscli2.zip
aws/install --update --install-dir ~/SageMaker/.initsmnb.d/aws-cli-v2 --bin-dir ~/SageMaker/.initsmnb.d/bin
sudo ln -s ~/SageMaker/.initsmnb.d/bin/aws /usr/local/bin/aws2 || true
rm /tmp/awscli2.zip
rm -fr /tmp/aws/

# Upgrade awscli to v2
# if [ ! -f $WORKING_DIR/bin/awscliv2.zip ]; then
#   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$WORKING_DIR/bin/awscliv2.zip"
#   # unzip -qq awscliv2.zip -C
#   unzip -o $WORKING_DIR/bin/awscliv2.zip -d $WORKING_DIR/bin
# fi
# sudo $WORKING_DIR/bin/aws/install --update
# rm -f /home/ec2-user/anaconda3/envs/JupyterSystemEnv/bin/aws
# sudo mv ~/anaconda3/bin/aws ~/anaconda3/bin/aws1
# ls -l /usr/local/bin/aws

AWS_COMPLETER=$(which aws_completer)
echo $SHELL

cat >> ~/.bashrc <<EOF
complete -C '${AWS_COMPLETER}' aws
complete -C '${AWS_COMPLETER}' a
EOF

source ~/.bashrc

aws configure set default.region ${AWS_REGION}
aws configure get default.region
aws configure set region $AWS_REGION
aws --version

# Borrow these settings from aws-samples hpc repo
aws configure set default.s3.max_concurrent_requests 100
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.cli_auto_prompt on-partial


echo "==============================================="
echo " AI/ML tools ......"
echo "==============================================="
# Ask bedrock
pip install ask-bedrock

if [ -f $CUSTOM_DIR/profile_bedrock_config ]; then
  # cat $CUSTOM_DIR/profile_bedrock_config >> ~/.aws/config
  # cat $CUSTOM_DIR/profile_bedrock_credentials >> ~/.aws/credentials
  cp $CUSTOM_DIR/profile_bedrock_config ~/.aws/config
  cp $CUSTOM_DIR/profile_bedrock_credentials ~/.aws/credentials  
fi

if [ -f $CUSTOM_DIR/abc_config ]; then
  mkdir -p /home/ec2-user/.config/ask-bedrock
  cp $CUSTOM_DIR/abc_config $HOME/.config/ask-bedrock/config.yaml
fi


echo "==============================================="
echo "  More Common tools ......"
echo "==============================================="

#https://github.com/lutzroeder/netron
pip install netron
# pip install cleanipynb # cleanipynb xxx.ipynb # 注意会把所有的图片附件都清掉
netron --version
# netron [FILE] or netron.start('[FILE]').
python3 -m pip install awscurl
pip3 install httpie


# Install session-manager
if [ ! -f $CUSTOM_DIR/bin/session-manager-plugin.rpm ]; then
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "$WORKING_DIR/bin/session-manager-plugin.rpm"
fi
sudo yum install -y $CUSTOM_DIR/bin/session-manager-plugin.rpm
session-manager-plugin

# ec2-instance-selector
if [ ! -f $CUSTOM_DIR/bin/ec2-instance-selector ]; then
  target=$(uname | tr '[:upper:]' '[:lower:]')-amd64
  LATEST_DOWNLOAD_URL=$(curl --silent $CUSTOM_DIR/bin/ec2-instance-selector "https://api.github.com/repos/aws/amazon-ec2-instance-selector/releases/latest" | grep "\"browser_download_url\": \"https.*$target.tar.gz" | sed -E 's/.*"([^"]+)".*/\1/')
  curl -Lo $CUSTOM_DIR/bin/ec2-instance-selector.tar.gz $LATEST_DOWNLOAD_URL
  tar -xvf $CUSTOM_DIR/bin/ec2-instance-selector.tar.gz -C $CUSTOM_DIR/bin
  # curl -Lo $CUSTOM_DIR/bin/ec2-instance-selector https://github.com/aws/amazon-ec2-instance-selector/releases/download/v2.4.1/ec2-instance-selector-`uname | tr '[:upper:]' '[:lower:]'`-amd64 
  chmod +x $CUSTOM_DIR/bin/ec2-instance-selector
fi

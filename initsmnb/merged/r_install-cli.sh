#!/bin/bash

set -euo pipefail

# source ~/.bashrc # 会有冲突

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

# Borrow these settings from aws-samples hpc repo
aws configure set default.s3.max_concurrent_requests 100
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.cli_auto_prompt on-partial

export AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

aws configure set default.region ${AWS_REGION}
aws configure get default.region
aws configure set region $AWS_REGION
aws --version

# # Upgrade awscli to v2
# if [ ! -f $WORKCUSTOM_DIRING_DIR/bin/awscliv2.zip ]; then
#   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$CUSTOM_DIR/bin/awscliv2.zip"
#   # unzip -qq awscliv2.zip -C
#   unzip -o $CUSTOM_DIR/bin/awscliv2.zip -d $CUSTOM_DIR/bin
# fi
# sudo $CUSTOM_DIR/bin/aws/install --update
# rm -f /home/ec2-user/anaconda3/envs/JupyterSystemEnv/bin/aws
sudo mv ~/anaconda3/bin/aws ~/anaconda3/bin/aws1
sudo rm -fr /usr/local/bin/aws
sudo ln -s ~/SageMaker/.initsmnb.d/bin/aws /usr/local/bin/aws || true
# ls -l /usr/local/bin/aws

AWS_COMPLETER=$(which aws_completer)
echo $SHELL
cat >> ~/.bashrc <<EOF
complete -C '${AWS_COMPLETER}' aws
complete -C '${AWS_COMPLETER}' a
EOF
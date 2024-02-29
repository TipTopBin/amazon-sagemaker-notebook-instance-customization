#!/bin/bash

mkdir -p ~/SageMaker/.initsmnb.d/docker/

sudo ~ec2-user/anaconda3/bin/python -c "
import json

with open('/etc/docker/daemon.json') as f:
    d = json.load(f)

d['data-root'] = '/home/ec2-user/SageMaker/.initsmnb.d/docker'

with open('/etc/docker/daemon.json', 'w') as f:
    json.dump(d, f, indent=4)
    f.write('\n')
"

# echo "==============================================="
# echo "  Optimize Disk Space ......"
# echo "==============================================="
# # https://docs.aws.amazon.com/sagemaker/latest/dg/docker-containers-troubleshooting.html
# mkdir -p ~/.sagemaker
# cat > ~/.sagemaker/config.yaml <<EOF
# local:
#   container_root: /home/ec2-user/SageMaker/tmp
# EOF
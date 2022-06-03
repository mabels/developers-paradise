stop=1
systemctl start docker.service
while [ $stop -ne 0 ]
do
  docker network inspect bridge > out.json
  stop=$?
  if [ $stop = 0 ]
  then
    bindip=$(jq -r '.[0].IPAM.Config[0].Gateway' < out.json)
    rm -f out.json
    mkdir -p /etc/systemd/system/docker.service.d
    cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://$bindip:2376 --containerd=/run/containerd/containerd.sock
EOF
    systemctl stop docker.service
    systemctl daemon-reload
    systemctl start docker.service
    waitDocker=1
    while [ $waitDocker -ne 0 ]
    do
      DOCKER_HOST=tcp://$bindip:2376 docker ps
      waitDocker=$?
      if [ $waitDocker -ne 0 ]
      then
        sleep 5
      fi
    done
    export DOCKER_HOST=tcp://$bindip:2376
  else
    sleep 5
  fi
done

cat > /tmp/start.sh <<EOF1
#!/bin/bash
su runner -c 'export DOCKER_HOST=$DOCKER_HOST; cd /home/runner/actions-runner && /home/runner/actions-runner/start-worker.sh ./run.sh'
EOF1
docker run \
	     -v /tmp/start.sh:/tmp/start.sh \
	     -e DOCKER_HOST=$DOCKER_HOST \
	     -e GITHUB_ACCESS_TOKEN="\$GITHUB_ACCESS_TOKEN" \
	     -e RUNNER_NAME="dp-$ARCH-$REV --ephemeral" \
	     -e CONFIG_OPTS="--ephemeral" \
	     -e RUNNER_LABELS="$REV" \
	     -e RUNNER_REPOSITORY_URL=https://github.com/${USER}/${PROJECT} \
	     public.ecr.aws/mabels/developers-paradise:$DOCKER_TAG \
	     bash /tmp/start.sh && \
poweroff && \
exit 0
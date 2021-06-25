FROM alpine:latest
RUN apk add --no-cache python3 py3-pip
RUN pip3 install requests
RUN apk update && apk add curl git
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
RUN chmod u+x kubectl && mv kubectl /bin/kubectl

COPY check_pods_update_view.py /

RUN chmod +x /check_pods_update_view.py

CMD ["/check_pods_update_view.py"]

#FROM hello-world

FROM python:3.11-slim-bookworm
#Installing pip packages
COPY requirements.txt /
RUN pip install -r /requirements.txt
ADD main.py /
ADD .env /
ADD coreOutput.json /
ADD setEnv.py /
WORKDIR /
RUN mkdir /data
RUN apt update -y && apt install default-jre -y
CMD ["python", "main.py"]

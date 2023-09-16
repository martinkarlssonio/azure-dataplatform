FROM deploy-image
USER root
ADD scripts /scripts/
ADD core /core/
ADD containers /containers
ADD notebooks /notebooks
ADD main.py /
ADD setCred.sh /
RUN mkdir /output
#WORKDIR /core
CMD ["python3", "/main.py"]

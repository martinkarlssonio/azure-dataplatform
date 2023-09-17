FROM deploy-image
USER root
ADD core /core/
ADD containers /containers
ADD notebooks /notebooks
ADD main.py /
ADD setCred.sh /
RUN mkdir /output
CMD ["python3", "/main.py"]

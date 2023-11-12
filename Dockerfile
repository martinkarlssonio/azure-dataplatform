FROM deploy-image
USER root
ADD core /core/
ADD containers /containers
ADD notebooks /notebooks
ADD main.py /
ADD setCred.sh /
# ADD .azure /
# ADD .azure ~/.azure
# ADD .azure /root/.azure
RUN mkdir /output
CMD ["python3", "/main.py"]

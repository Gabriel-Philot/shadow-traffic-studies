FROM jupyter/pyspark-notebook:latest

USER root

# Install additional Python packages
RUN pip install --no-cache-dir \
    delta-spark \
    boto3 \
    s3fs \
    matplotlib \
    seaborn \
    pandas \
    pyarrow

# Create work directory
RUN mkdir -p /home/jovyan/work && \
    chmod 777 /home/jovyan/work

# Switch back to jovyan user
USER jovyan

# Set environment variables for Spark
ENV PYSPARK_SUBMIT_ARGS="--packages io.delta:delta-core_2.12:2.1.0,org.apache.hadoop:hadoop-aws:3.3.1 pyspark-shell"

# Start JupyterLab without requiring a token/password
CMD ["start-notebook.sh", "--NotebookApp.token=''", "--NotebookApp.password=''"]
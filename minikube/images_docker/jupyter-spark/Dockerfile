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

# Create directories for resources and configs
RUN mkdir -p /home/jovyan/resources /home/jovyan/config /home/jovyan/work && \
    chown -R jovyan:users /home/jovyan/resources /home/jovyan/config /home/jovyan/work

# Switch back to jovyan user
USER jovyan

# Set environment variables for Spark
ENV PYSPARK_SUBMIT_ARGS="--packages io.delta:delta-core_2.12:2.1.0,org.apache.hadoop:hadoop-aws:3.3.1 pyspark-shell"

# Define the startup command for JupyterLab - simpler like your original
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
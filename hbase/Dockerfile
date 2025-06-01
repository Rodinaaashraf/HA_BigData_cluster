FROM hadoop-ha:v1

USER root

# Set environment variables
ENV HBASE_HOME=/opt/hbase
ENV PATH=$PATH:$HBASE_HOME/bin


# Install HBase
ADD https://archive.apache.org/dist/hbase/2.4.9/hbase-2.4.9-bin.tar.gz /hbase.tar.gz
RUN tar -xzvf /hbase.tar.gz -C /opt && \
    mv /opt/hbase-2.4.9 /opt/hbase && \
    rm /hbase.tar.gz

# Switch to hadoop user

RUN mkdir -p /opt/hbase/logs && \
    chown -R hadoop:hadoop /opt/hbase

USER hadoop

# Copy config and entrypoint (to be added in your docker-compose bind mounts or image context)
COPY hbase-site.xml $HBASE_HOME/conf
COPY hbase-env.sh $HBASE_HOME/conf
COPY regionservers $HBASE_HOME/conf

USER root
COPY --chown=hadoop:hadoop entrypoint.sh /home/hadoop/entrypoint.sh
RUN chmod +x /home/hadoop/entrypoint.sh

USER hadoop
ENTRYPOINT ["bash", "/home/hadoop/entrypoint.sh"]

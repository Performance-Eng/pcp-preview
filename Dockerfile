FROM fedora:42

LABEL maintainer="Performance Co-Pilot Team"
LABEL org.opencontainers.image.authors="Performance Co-Pilot Team"
LABEL org.opencontainers.image.url="github.com/Performance-Eng/pcp-preview"
LABEL org.opencontainers.image.documentation="github.com/Performance-Eng/pcp-preview"
LABEL org.opencontainers.image.source="github.com/Performance-Eng/pcp-preview"
LABEL org.opencontainers.image.vendor="Performance Co-Pilot Team"
LABEL org.opencontainers.image.title="Performance Co-Pilot Preview"
LABEL org.opencontainers.image.description="Performance Co-Pilot Preview Container image with Grafana and PCP plugins"

ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS="performancecopilot-pcp-app,pcp-valkey-datasource,pcp-vector-datasource,pcp-bpftrace-datasource,pcp-flamegraph-panel,pcp-breadcrumbs-panel,pcp-troubleshooting-panel,performancecopilot-valkey-datasource,performancecopilot-vector-datasource,performancecopilot-bpftrace-datasource,performancecopilot-flamegraph-panel,performancecopilot-breadcrumbs-panel,performancecopilot-troubleshooting-panel"

RUN dnf install -y --setopt=tsflags=nodocs \
	redis grafana-pcp pcp-zeroconf \
	pcp-pmda-bcc pcp-pmda-bpftrace \
	kmod procps bcc-tools bpftrace curl wget unzip && \
    dnf clean all && \
    touch /var/lib/pcp/pmdas/{bcc,bpftrace}/.NeedInstall

RUN wget https://github.com/performancecopilot/grafana-pcp/releases/download/v5.3.0/performancecopilot-pcp-app-5.3.0.zip && \
	unzip -f -d /var/lib/grafana/plugins/ performancecopilot-pcp-app-5.3.0.zip && \
	rm -f performancecopilot-pcp-app-5.3.0.zip

RUN sudo sed -i 's/;allow_loading_unsigned_plugins =/allow_loading_unsigned_plugins = performancecopilot-pcp-app,pcp-valkey-datasource,pcp-vector-datasource,pcp-bpftrace-datasource,pcp-flamegraph-panel,pcp-breadcrumbs-panel,pcp-troubleshooting-panel,performancecopilot-valkey-datasource,performancecopilot-vector-datasource,performancecopilot-bpftrace-datasource,performancecopilot-flamegraph-panel,performancecopilot-breadcrumbs-panel,performancecopilot-troubleshooting-panel/' /etc/grafana/grafana.ini

COPY grafana.ini /etc/grafana/grafana.ini
COPY grafana-configuration.service /etc/systemd/system
COPY datasource.yaml /usr/share/grafana/conf/provisioning/datasources/grafana-pcp.yaml
COPY bpftrace.conf /var/lib/pcp/pmdas/bpftrace/bpftrace.conf

RUN systemctl enable redis grafana-server grafana-configuration
RUN systemctl enable pmcd pmie pmlogger pmproxy

# PCP archives (auto-discovered by pmproxy), REST API, PCP port
VOLUME ["/var/log/pcp/pmlogger"]
EXPOSE 44322
EXPOSE 44321

# Redis RDB files and Redis RESP port
VOLUME ["/var/lib/redis"]
EXPOSE 6379

# Grafana DB and REST API port
VOLUME ["/var/lib/grafana"]
EXPOSE 3000

CMD ["/usr/sbin/init"]

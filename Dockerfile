ARG VERSION="0.5.1"
ARG APP_BUILD_ROOT=/opt/app-root

FROM registry.redhat.io/ubi9/go-toolset:9.7@sha256:dc1f887fd22e4cc112f59b3173754ef97f1c6b7202a720e697b2798d8053b7be AS builder

ARG TARGETOS
ARG TARGETARCH
ARG APP_BUILD_ROOT

ENV GOEXPERIMENT=strictfipsruntime
ENV APP_ROOT=$APP_BUILD_ROOT
ENV CGO_ENABLED=1
ENV GOPATH=$APP_ROOT

WORKDIR $APP_ROOT/src/
COPY go.mod ./
COPY go.sum ./
COPY cmd/main.go cmd/main.go
COPY api/ api/
COPY internal/ internal/
COPY pkg/ pkg/
RUN go mod download && \
    CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -a -o ${APP_ROOT}/manager cmd/main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:3aea404f9e7a55d36d93c15af9bc0e4965b871ef63c3bbd4a0746bffdf5203eb AS deploy

ARG VERSION
ARG APP_BUILD_ROOT

WORKDIR /
COPY --from=builder ${APP_BUILD_ROOT}/manager .
COPY LICENSE /licenses/license.txt
USER 65532:65532

LABEL description="The Workload Variant Autoscaler dynamically scales workload variants based on demand, enabling efficient multi-variant LLM inference on Kubernetes."
LABEL io.k8s.description="A Kubernetes controller that implements autoscaling logic for inference server variants, integrating with Gateway API Inference Extension and vLLM resources to optimize LLM inference capacity."
LABEL io.k8s.display-name="Workload Variant Autoscaler"
LABEL summary="Kubernetes controller for autoscaling inference containers"
LABEL com.redhat.component="workload-variant-autoscaler-controller"
LABEL name="workload-variant-autoscaler"
LABEL io.openshift.tags="workload-variant-autoscaler llm-d rhoai"
LABEL org.opencontainers.image.source="https://github.com/opendatahub-io/workload-variant-autoscaler"
LABEL org.opencontainers.image.description="Workload Variant Autoscaler (WVA) - GPU-aware autoscaler for LLM inference workloads"
LABEL org.opencontainers.image.licenses="Apache-2.0"

LABEL features.operators.openshift.io/cni="false"
LABEL features.operators.openshift.io/disconnected="true"
LABEL features.operators.openshift.io/fips-compliant="true"
LABEL features.operators.openshift.io/proxy-aware="true"
LABEL features.operators.openshift.io/cnf="false"
LABEL features.operators.openshift.io/csi="false"
LABEL features.operators.openshift.io/tls-profiles="false"
LABEL features.operators.openshift.io/token-auth-aws="false"
LABEL features.operators.openshift.io/token-auth-azure="false"
LABEL features.operators.openshift.io/token-auth-gcp="false"

ENTRYPOINT ["/manager"]

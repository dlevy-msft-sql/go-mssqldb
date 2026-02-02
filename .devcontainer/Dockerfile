# Go MSSQL Driver Development Container
FROM mcr.microsoft.com/devcontainers/go:1-1.24-bookworm

# Install go-sqlcmd (uses the go-mssqldb driver - dogfooding!)
# Also install Kerberos libs for integrated auth testing
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y curl libkrb5-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install go-sqlcmd - the Go-based sqlcmd that uses go-mssqldb
RUN go install github.com/microsoft/go-sqlcmd/cmd/sqlcmd@latest

# Install golangci-lint for code quality
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.64.8

# Install additional Go tools
RUN go install golang.org/x/tools/gopls@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install honnef.co/go/tools/cmd/staticcheck@latest

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

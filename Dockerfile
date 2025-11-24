ARG ROS_VERSION=humble

# Include perception packages, but not necessarily full desktop 
FROM ros:$ROS_VERSION-ros-perception

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /root/ws_riskam
COPY . src/riskam_ros

# Install apt packages needed for CI
RUN apt-get -q update \
    && apt-get -q -y upgrade \
    && apt-get -q install --no-install-recommends -y \
    git \
    sudo \
    clang \
    clang-format-14 \
    clang-tidy \
    clang-tools \
    python3-pip \
    python3-dev \
    python3-venv \
    lsb-release \
    wget \
    gnupg \
    software-properties-common \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install all ROS dependencies for riskam
RUN apt-get -q update \
    && apt-get -q -y upgrade \
    && rosdep update \
    && rosdep install -y --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} --as-root=apt:false \
    && rm -rf src \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Configure a new non-root user
ARG USERNAME=riskam
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && usermod -a -G dialout $USERNAME \
    && echo "source /usr/share/bash-completion/completions/git" >> /home/$USERNAME/.bashrc

ENV DEBIAN_FRONTEND=noninteractive

# Switch to the non-root user for the rest of the installation
USER $USERNAME
ENV USER=$USERNAME

#Import the necessary repos: 
RUN vcs import src < src/riskam_ros/riskam.repos
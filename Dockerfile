ARG HOST_OS=l4t-r36.2.0
ARG ROS_DISTRO=humble
ARG PREFIX=

FROM dustynv/ros:${ROS_DISTRO}-desktop-${HOST_OS} AS ros_base
SHELL ["/bin/bash", "-c"]

#Update the ROS2 Humble GPG key
RUN apt-get update || true \
    && apt-get install -y curl gnupg \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ENV ROS_USER=RiskAM
ARG ROS_USER_UID=1000
ARG ROS_USER_GID=$ROS_USER_UID

RUN groupadd --gid $ROS_USER_GID $ROS_USER \
    && useradd -s /bin/bash --uid $ROS_USER_UID --gid $ROS_USER_GID -m $ROS_USER \
    # [Optional] Add sudo support for the non-root user
    && apt-get update \
    && apt-get install -y sudo \
    && echo $ROS_USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$ROS_USER\
    && chmod 0440 /etc/sudoers.d/$ROS_USER \
    && usermod -a -G dialout $USERNAME \
    && echo "source /usr/share/bash-completion/completions/git" >> /home/$USERNAME/.bashrc \ 
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt upgrade -y \
  # install build tools
  && apt-get install -y \
    git \
    alsa-utils \
    build-essential \
    python3-pip \
    python3-rosdep \
    python3-vcstools \
    python3-colcon-common-extensions \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root/coresense_ws
COPY . src/riskam_ros

# Remove unnecessary folders
RUN rm -rf log 

# Set up the entrypoint
ENTRYPOINT [ "/ros_entrypoint.sh" ]
CMD ["bash"]
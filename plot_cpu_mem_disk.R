# Title     : CPU MEM DISK Usage Plot 
# Objective : TODO
# Created by: chenchen
# Created on: 4/17/19

library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(gridExtra)

args <- commandArgs(T)

mycolors <- brewer.pal(7, "Set1")
#prefix <- "01.WGS.MegaBOLT"
prefix <- args[1]

cpuFile <- paste(prefix, ".cpu.dat", sep="")
memFile <- paste(prefix, ".mem.dat", sep="")
ioFile <- paste(prefix, ".io.dat", sep="")
storageFile <- paste(prefix, ".storage.dat", sep="")

myTheme <- theme(plot.title=element_text(hjust=0.5), 
                 # plot.margin=margin(0, 0, 0, 0),
                 axis.text.x=element_text(size=5), 
                 legend.position="top", 
                 legend.title=element_text(size=7),
                 legend.text=element_text(size=7),
                 legend.margin=margin(0, 0, 0, 0),
                 legend.box.margin=margin(0, 0, 0, 0))

# CPU
a <- read.table(cpuFile, head=T)

maxTime <- ((max(a$Time) %/% 500) + 1) * 500

dat <- melt(a, value.name="CPU_Usage", id.vars="Time", variable.name="CPU")
cpuplot <- ggplot(data=dat, mapping=aes(x=Time, y=CPU_Usage)) +
    geom_line(color=mycolors[1], linetype=2) +
    geom_point(color=mycolors[1], shape=20) +
    # geom_line() + 
    # geom_point() +
    scale_x_continuous(breaks=seq(0, maxTime, by=500)) +
    scale_y_continuous(breaks=seq(0, 80, by=10), limits=c(0, 80)) +
    labs(title="CPU Usage", x="Time (s)", y="Thread Number") + 
    myTheme

# ggsave(file="CPU.pdf", plot=cpuplot)

# MEM
a <- read.table(memFile, head=T)

dat <- melt(a, value.name="MEM_Usage", id.vars="Time", variable.name="MEM")
memplot <- ggplot(data=dat, mapping=aes(x=Time, y=MEM_Usage)) +
    geom_line(color=mycolors[2], linetype=2) +
    geom_point(color=mycolors[2], shape=20) +
    scale_x_continuous(breaks=seq(0, maxTime, by=500)) +
    scale_y_continuous(breaks=seq(0, 256, by=20), limits=c(0, 256)) +
    labs(title="Memory Usage", x="Time (s)", y="Memory (GB)") + 
    myTheme

# ggsave(file="MEM.pdf", plot=memplot)

# DISK IO
a <- read.table(ioFile, head=T)

dat <- melt(a, value.name="IO_Usage", id.vars="Time", variable.name="IO")
ioplot <- ggplot(data=dat, mapping=aes(x=Time, y=IO_Usage, shape=IO, colour=IO)) +
    geom_line(size=0.5) + geom_point(size=0.5) +
    scale_x_continuous(breaks=seq(0, maxTime, by=500)) +
    labs(title="Disk IO Throughput", x="Time (s)", y="IO (MB/s)") + 
    myTheme

# ggsave(file="IO.pdf", plot=ioplot)

# Storage
a <- read.table(storageFile, head=T)

maxStorage <- ((max(a$Total) %/% 50) + 1) * 50

dat <- melt(a, value.name="Storage_Usage", id.vars="Time", variable.name="Storage")
storageplot <- ggplot(data=dat, mapping=aes(x=Time, y=Storage_Usage, shape=Storage, colour=Storage)) +
    geom_line(size=0.5) + geom_point(size=0.5) +
    scale_x_continuous(breaks=seq(0, maxTime, by=500)) +
    scale_y_continuous(breaks=seq(0, maxStorage, by=50), limits=c(0, maxStorage)) +
    labs(title="Temp Storage Used", x="Time (s)", y="Storage (GB)") + 
    myTheme

# ggsave(file="Storage.pdf", plot=storageplot)

# Full plot
fullplot <- grid.arrange(cpuplot, ioplot, memplot, storageplot)
fileName <- paste(prefix, ".pdf", sep="")
ggsave(file=fileName, plot=fullplot, width=9, height=6)

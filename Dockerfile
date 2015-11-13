FROM kbase/sdkbase:latest
MAINTAINER KBase Developer
# -----------------------------------------

# Insert apt-get instructions here to install
# any required dependencies for your module.

# RUN apt-get update
ENV R_LIBS=/kb/deployment/lib
RUN R -q -e 'if(!require(jsonlite)) install.packages("jsonlite", repos="http://cran.us.r-project.org")'
RUN R -q -e 'if(!require(httr)) install.packages("httr", repos="http://cran.us.r-project.org")'
RUN R -q -e 'if(!require(raster)) install.packages("raster", repos="http://cran.us.r-project.org")'
RUN apt-get -y install r-cran-evaluate r-cran-codetools r-cran-testthat
RUN R -q -e 'if(!require(clValid)) install.packages("clValid", repos="http://cran.us.r-project.org")'
RUN R -q -e 'if(!require(fpc)) install.packages("fpc", repos="http://cran.us.r-project.org")'

# -----------------------------------------

COPY ./ /kb/module
RUN mkdir -p /kb/module/work

WORKDIR /kb/module

RUN make

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]

#' NT Spatial Weights Matrix for Unbalanced TSCS Samples.
#'
#' \code{make_ntspmat} generates a nearest neighbor spatial
#' weights matrix for an unbalanced TSCS sample used to
#' estimate a linear regression model.
#'
#' @param lmobj An object created by the \code{lm} function.
#' @param ci Name of a variable that identifies countries.
#' @param yi Name of a variable that identifies years.
#' @param k A value that determines the number of nearest
#' neighbors.
#' @return The output will be a matrix.
#'
#' @examples
#' df <- data.frame(
#' country = factor(c("United Kingdom","United Kingdom","Ireland","Ireland",
#' "Netherlands","Netherlands", "Belgium","Belgium","France","France","Spain","Spain")),
#' year = c(2018, 2019, 2018, 2019, 2018, 2019, 2018, 2019, 2018, 2019, 2018, 2019),
#' y = rnorm(12), x = rnorm(12))
#' linmod <- lm(y~x,df)
#' w <- make_ntspmat(linmod,country,year,3)
#'
#' @import dplyr
#' @importFrom stats na.omit
#' @importFrom sf as_Spatial
#' @importFrom Matrix bdiag
#' @importFrom lubridate year
#' @import cshapes
#' @import stargazer
#' @export
make_ntspmat <- function(lmobj,ci,yi,k) {

  # defining global variables
  CNTRY_NAME <- COWSYEAR <- NULL

  # Identify and subset the sample (df) from the regression, using the estimated disturbances.

  call <- match.call()
  esample<-rownames(as.matrix(lmobj[["residuals"]]))
  df <- eval(lmobj[["call"]][["data"]])
  df <- df[esample,]

  # Collect Information about the sample: (country names: c), (years: y), and (max number of time period: yl)


  c<-with(df,unique(eval(parse(text = noquote(paste(call$ci))))))
  y<-with(df,sort(unique(eval(parse(text = noquote(paste(call$yi))))),decreasing=FALSE))
  yl<-length(y)



  # Identify start year for each country in the sample (start_dta)

  start_dta <- as_tibble(df) %>%
    arrange(desc(-as.numeric(eval(parse(text=noquote(paste(call$yi))))))) %>%
    group_by(as.factor(eval(parse(text=noquote(paste(call$ci)))))) %>%
    slice(1) %>%
    ungroup()


  # Load Cshapes Data into cshp.dat


  suppressWarnings(cshp.dat <- cshp(useGW = FALSE))


  # Reformat COW Entry Date

  cshp.dat$COWSYEAR <- year(cshp.dat$start)


  # Convert to Spatial DataFrame

  cshp.dat <- as_Spatial(cshp.dat)



  # Create a DataFrame that has COW country name, code and entry year.

  cow <- cbind(as.data.frame(cshp.dat$country_name),as.data.frame(cshp.dat$cowcode),as.data.frame(cshp.dat$COWSYEAR))

  names(cow)[1:3]<- c("CNTRY_NAME","COWCODE","COWSYEAR")

  cow<-as_tibble(cow) %>%
    arrange(desc(-as.numeric(COWSYEAR))) %>%
    group_by(CNTRY_NAME) %>%
    slice(1) %>%
    ungroup()

  cow$COWSYEAR<-as.numeric(as.character(cow$COWSYEAR))
  cow$CNTRY_NAME<-as.character(cow$CNTRY_NAME)

  # To Help with Debugging
  #  browser()



  # Match start_dta (year country enters dataset) with cow (year country enters cow)

  o <- match(start_dta$`as.factor(eval(parse(text = noquote(paste(call$ci)))))`,cow$CNTRY_NAME)
  cow <- cow[o,]

  # Create a new DataFrame that contains both entry years (dataset and COW)

  start_match <- cbind(start_dta,cow)

  # Check to see if COW entry data precedes entry date in dataset. If diff2 == 1, this condition does not hold. If diff2 < 0, condition holds.

  start_match$diff<- start_match$COWSYEAR - as.numeric(as.character(eval(parse(text=noquote(paste("start_match$",call$yi,sep=""))))))
  start_match$diff2 <- ifelse(start_match$diff > 0, 1, start_match$diff)

  # Identify Countries that enter the dataset prior to entering COW or have missing COW codes

  start_match2 <- na.omit(start_match[start_match$diff2==1,])
  start_match <- start_match[is.na(start_match[,"COWCODE"]),]

  # Collect these cases and label Columns.

  if(nrow(start_match2) > 0) {
    start_match2 <- rbind(start_match2,start_match)
  } else{
    start_match2 <- start_match
  }

  start_match2<-start_match2[,c(paste(call$ci),paste(call$yi),"CNTRY_NAME","COWSYEAR")]
  colnames(start_match2)<-c("Data Country Name", "Data Start Year","COW Country Name","COW Start Year")
  start_match2$"Data Start Year"<- as.character(start_match2$"Data Start Year")
  start_match2$"COW Start Year"<- as.character(start_match2$"COW Start Year")
  rownames(start_match2) <- c()

  # Create a table and error message if there are any countries that enter the dataset prior to entering COW or have missing COW codes. Note that at the moment corrections need to be made manually to the dataset prior to calling the function.



  if(nrow(start_match2) > 0) {
    stargazer(start_match2[,c(1,2)],type="text",summary=FALSE)
    stop('Some of your Country-Years are not Matched. You can use the following functions to help you match Country Names and Years of your data with cshapes: names_list() provides the list of all country names, and to check starting and ending date use name_text("Country Name") or name_code(warcode)')
  }


  # If there are no problems, merge COW with User's dataset and Create a Unique Country-Year Identifier (coln).

  o <- match(eval(parse(text=noquote(paste("df$",call$ci,sep="")))),cow$CNTRY_NAME)
  cow<-cow[o,]
  df.m <- cbind(df,cow)
  df.m$coln <- paste(df.m$COWCODE,df.m$year,sep=".")


  # Create a Distance Matrix for the first year in the user's dataset.

  dmat <- suppressWarnings(as.data.frame(distmatrix(as.Date(paste0(as.character.Date(y[1]),"-12-31",""),"%Y-%m-%d"), type="capdist", useGW=F, dependencies = TRUE, keep=1)))

  # Create first block diagonal of the NT x NT weights matrix. Collect the cross-section of countries (by COWCODE) present in the first year of the user's dataset. Create a distance matrix.

  #dta <-df.m[which(df.m$year==as.numeric(as.character(y[1]))), ]


  dta <-df.m[which(eval(parse(text=noquote(paste("df.m$",call$yi,sep=""))))==as.numeric(as.character(y[1]))), ]

  dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="German Federal Republic", "255",dta$COWCODE)
   dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="Yemen (Arab Republic of Yemen)", "679",dta$COWCODE)
   dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1968 & dta[[noquote(paste(call$ci))]]=="Yemen, People's Republic of", "678",dta$COWCODE)
   dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="Yemen, People's Republic of", "679",dta$COWCODE)
   dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2002 & dta[[noquote(paste(call$ci))]]=="East Timor", "850",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Latvia", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Ukraine", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Armenia", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Belarus (Byelorussia)", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Azerbaijan", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Eritrea", "530",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Georgia", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Kyrgyz Republic", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Uzbekistan", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Kazakhstan", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Moldova", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Turkmenistan", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Tajikistan", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="German Democratic Republic", "255",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Czech Republic", "315",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Estonia", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Latvia", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Lithuania", "365",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Slovenia", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Bosnia-Herzegovina", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Croatia", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Macedonia (FYROM/North Macedonia)", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2007 & dta[[noquote(paste(call$ci))]]=="Montenegro", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2009 & dta[[noquote(paste(call$ci))]]=="Kosovo", "345",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1957 & dta[[noquote(paste(call$yi))]] < 1961 & dta[[noquote(paste(call$ci))]]=="Syria", "651",dta$COWCODE)
  # #  dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1976 & dta[[noquote(paste(call$ci))]]=="Singapore", "820",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1976 & dta[[noquote(paste(call$ci))]]=="Vietnam, Republic of", "816",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Slovakia", "315",dta$COWCODE)
  # dta$COWCODE <- ifelse(dta[[noquote(paste(call$ci))]]=="Zanzibar", "510",dta$COWCODE)

  cs <- na.omit(unique(dta$COWCODE))
  csl <- length(cs)

  # To Help with Debugging
  #  browser()

  dmat<-dmat[as.character(cs), as.character(cs)]

  # Create Unique Country-Year Identifier.

  coln <- paste(colnames(dmat),y[1],sep=".")

  # Create an error message if there are fewer countries in the cross-section than k.

  dcol <- ncol(dmat)

  if(dcol <= k) {
    stop('You only have k or fewer countries in your cross-section. Choose a smaller k.')
  }


  initial <- matrix(0,nrow=dcol,ncol=dcol)
  initial[c(1:k+1),] <- 1
  initial <- matrix(initial,ncol=1)

  # Rank the distances...
  dorder <- apply(dmat,2,order) %>%
    matrix(ncol=1)

  seq <- seq(0,dcol-1)
  mmult <- diag(seq)
  mmult2 <- matrix(dcol,nrow=dcol,ncol=dcol)
  adj <- (mmult2%*%mmult) %>%
    matrix(ncol=1)

  dorder <- dorder + adj

  seq <- as.matrix(seq(1,dcol*dcol))
  dorder <- cbind(dorder,seq)

  dorder <- dorder[order(dorder[,1],decreasing=FALSE),]
  dorder<-dorder[,2]

  nnmat <- as.matrix(initial[dorder]) %>%
    matrix(nrow = dcol, byrow = TRUE)

  colnames(nnmat)<-coln
  rownames(nnmat)<-coln

  cyi <- as.data.frame(coln)
  nnmat_b <- nnmat
  dfo <- dta

  print(noquote(as.character(y[1])))
  print(noquote(as.character(cs)))

  # Using Loop, Diagonally Concatenate Remaining Block Diagonal Matrices for Sparse NTxNT Matrix

  for (i in 2:yl) {

    dmat <- suppressWarnings(as.data.frame(distmatrix(as.Date(paste0(as.character.Date(y[i]),"-12-31",""),"%Y-%m-%d"), type="capdist", useGW=F, dependencies = TRUE, keep=1)))
    #  dta <-df.m[which(df.m$year==as.numeric(as.character(y[i]))), ]
    dta <-df.m[which(eval(parse(text=noquote(paste("df.m$",call$yi,sep=""))))==as.numeric(as.character(y[i]))), ]
    #These are less than ideal workarounds for illustrations. Country names stay the same, but cowcodes change in 1992.

     dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="German Federal Republic", "255",dta$COWCODE)
     dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="Yemen (Arab Republic of Yemen)", "679",dta$COWCODE)
     dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1968 & dta[[noquote(paste(call$ci))]]=="Yemen, People's Republic of", "678",dta$COWCODE)
     dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="Yemen, People's Republic of", "679",dta$COWCODE)
     dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2002 & dta[[noquote(paste(call$ci))]]=="East Timor", "850",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Latvia", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Ukraine", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Armenia", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Belarus (Byelorussia)", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Azerbaijan", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Eritrea", "530",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Georgia", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Kyrgyz Republic", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Uzbekistan", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Kazakhstan", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Moldova", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Turkmenistan", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Tajikistan", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1989 & dta[[noquote(paste(call$ci))]]=="German Democratic Republic", "255",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Czech Republic", "315",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Estonia", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Latvia", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1991 & dta[[noquote(paste(call$ci))]]=="Lithuania", "365",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Slovenia", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Bosnia-Herzegovina", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1992 & dta[[noquote(paste(call$ci))]]=="Croatia", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Macedonia (FYROM/North Macedonia)", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2007 & dta[[noquote(paste(call$ci))]]=="Montenegro", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 2009 & dta[[noquote(paste(call$ci))]]=="Kosovo", "345",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] > 1957 & dta[[noquote(paste(call$yi))]] < 1961 & dta[[noquote(paste(call$ci))]]=="Syria", "651",dta$COWCODE)
    # #    dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1976 & dta[[noquote(paste(call$ci))]]=="Singapore", "820",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1976 & dta[[noquote(paste(call$ci))]]=="Vietnam, Republic of", "816",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$yi))]] < 1993 & dta[[noquote(paste(call$ci))]]=="Slovakia", "315",dta$COWCODE)
    # dta$COWCODE <- ifelse(dta[[noquote(paste(call$ci))]]=="Zanzibar", "510",dta$COWCODE)




    cs <- as.character(na.omit(unique(dta$COWCODE)))
    cs_names_cow <- sort(as.character(na.omit(unique(cow$CNTRY_NAME))))
    cs_names_data <- sort(as.character(na.omit(unique(dta$CNTRY_NAME))))
    m <- match(cs_names_data,cs_names_cow)

    #    To Help with Debugging
    #    if (y[i]==1994) {
    #      browser()
    #    }



    csl <- length(cs)

    dmat<-dmat[as.character(cs), as.character(cs)]

    # Create Unique Country-Year Identifier.
    coln <- paste(colnames(dmat),y[i],sep=".")


    # Create an error message if there are fewer countries in the cross-section than k.

    dcol <- ncol(dmat)

    if(dcol <= k) {
      stop('You have k or fewer countries in your cross-section. Choose a smaller k.')
    }


    # Sort the distance matrix to identify k-nearest neighbors.

    initial <- matrix(0,nrow=dcol,ncol=dcol)
    initial[c(1:k+1),] <- 1
    initial <- matrix(initial,ncol=1)

    # Rank the distances...
    dorder <- apply(dmat,2,order) %>%
      matrix(ncol=1)

    seq <- seq(0,dcol-1)
    mmult <- diag(seq)
    mmult2 <- matrix(dcol,nrow=dcol,ncol=dcol)
    adj <- (mmult2%*%mmult) %>%
      matrix(ncol=1)

    dorder <- dorder + adj

    seq <- as.matrix(seq(1,dcol*dcol))
    dorder <- cbind(dorder,seq)

    dorder <- dorder[order(dorder[,1],decreasing=FALSE),]
    dorder<-dorder[,2]

    nnmat <- as.matrix(initial[dorder]) %>%
      matrix(nrow = dcol, byrow = TRUE)

    colnames(nnmat)<-coln
    rownames(nnmat)<-coln
    cyi <- rbind(as.data.frame(cyi),as.data.frame(coln))

    nnmat_b <- bdiag(nnmat_b,nnmat)
    dfo <- rbind(dfo,dta)
    print(noquote(as.character(y[i])))
    print(noquote(cs))
    print("All of your Countries are Matched.", quote=FALSE)

  }

  nnmat <- as.matrix(nnmat_b)
  wm2<-(list(dfo,nnmat))
  return(wm2)
}

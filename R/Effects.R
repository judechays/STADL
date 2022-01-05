setwd("C:/Users/Scott/OneDrive/Desktop/files")

rm(list=ls(all=TRUE))


install.packages("cshapes")
install.packages("dplyr")
install.packages("Matrix")
install.packages("spdep")
install.packages("spatialreg")
install.packages("stargazer")
install.packages("lubridate")
install.packages("tidyverse")
install.packages("DataCombine")

library(cshapes)
library(dplyr)
library(Matrix)
library(spdep)
library(spatialreg)
library(stargazer)
library(lubridate)
library(tidyverse)
library(DataCombine)
library(expm)   

data<-read.csv("aer_5year_APSR_full.csv")

reg<-lm(formula = polity4 ~ polity4L + lrgdpchL + as.factor(country) + as.factor(year), data = data)
summary(reg)

data$country<-recode_factor(data$country,"Korea, Rep."="Korea, Republic of")
data$country<-recode_factor(data$country,"Egypt, Arab Rep."="Egypt")
data$country<-recode_factor(data$country,"Gambia, The"="Gambia")
data$country<-recode_factor(data$country,"Ethiopia 1993-"="Ethiopia")
data$country<-recode_factor(data$country,"Ethiopia -pre 1993"="Ethiopia")
data$country<-recode_factor(data$country,"Pakistan-pre-1972"="Pakistan")
data$country<-recode_factor(data$country,"Pakistan-post-1972"="Pakistan")
data$country<-recode_factor(data$country,"Belarus"="Belarus (Byelorussia)")
data$country<-recode_factor(data$country,"Syrian Arab Republic"="Syria")
data$country<-recode_factor(data$country,"Venezuela, RB"="Venezuela")
data$country<-recode_factor(data$country,"Vietnam"="Vietnam, Democratic Republic of")
data$country<-recode_factor(data$country,"Russia"="Russia (Soviet Union)")
data$country<-recode_factor(data$country,"Yemen"="Yemen (Arab Republic of Yemen)")
data$country<-recode_factor(data$country,"United States"="United States of America")
data$country<-recode_factor(data$country,"Tanzania"="Tanzania (Tanganyika)")
data$country<-recode_factor(data$country,"Burkina Faso"="Burkina Faso (Upper Volta)")
data$country<-recode_factor(data$country,"Cambodia"="Cambodia (Kampuchea)")
data$country<-recode_factor(data$country,"Zimbabwe"="Zimbabwe (Rhodesia)")
data$country<-recode_factor(data$country,"Cote d'Ivoire"="Cote D'Ivoire")
data$country<-recode_factor(data$country,"Germany"="German Federal Republic")
data$country<-recode_factor(data$country,"Iran"="Iran (Persia)")
data$country<-recode_factor(data$country,"Italy"="Italy/Sardinia")
data$country<-recode_factor(data$country,"Turkey"="Turkey (Ottoman Empire)")
data$country<-recode_factor(data$country,"Congo, Dem. Rep."="Congo, Democratic Republic of (Zaire)")
data$country<-recode_factor(data$country,"Congo, Rep."="Congo")
data$country<-recode_factor(data$country,"Kyrgyzstan"="Kyrgyz Republic")
data$country<-recode_factor(data$country,"Madagascar"="Madagascar (Malagasy)")
data$country<-recode_factor(data$country,"Sri Lanka"="Sri Lanka (Ceylon)")
data$country<-recode_factor(data$country,"Macedonia, FYR"="Macedonia (FYROM/North Macedonia)")
data$country<-recode_factor(data$country,"Romania"="Rumania")


reg3<-lm(formula = polity4 ~ polity4L + lrgdpchL + as.factor(year), data = data)
wm2 <- make_ntspmat(reg3,country,year,10)
w2 <- as.matrix(wm2[[2]])
lag2 <- ntspreg(reg3,w2)
summary(lag2)


reg5<-lm(formula = polity4 ~ lrgdpchL + as.factor(country) + as.factor(year), data = data)
summary(reg5)
wm4 <- make_ntspmat(reg5,country,year,10)
w4 <- as.matrix(wm4[[2]])
lag4 <- ntspreg(reg5,w4)
summary(lag4)

reg6<-lm(formula = polity4 ~ lrgdpchL + as.factor(year), data = data)
summary(reg6)
wm5 <- make_ntspmat(reg6,country,year,10)
w5 <- as.matrix(wm5[[2]])
lag5 <- ntspreg(reg6,w5)
summary(lag5)

reg7<-lm(formula = polity4 ~ lrgdpchL,  data = data)
summary(reg7)
wm6 <- make_ntspmat(reg7,country,year,10)
w6 <- as.matrix(wm6[[2]])
lag6 <- ntspreg(reg7,w6)
summary(lag6)


###Balanced

esample<-rownames(as.matrix(lag2[["residuals"]]))
df <- data[esample,]

shock <- 2000
dim0 <- as.numeric(length(which(df$year < shock)))
dim1 <- as.numeric(length(which(df$year == shock)))

W <- as.matrix(w2/rowSums(w2))
W <- W[(dim0+1):(dim0+dim1),(dim0+1):(dim0+dim1)]

b <- summary(lag2)$coefficients[3]
r <- summary(lag2)$rho
p <- summary(lag2)$coefficients[2]
  
direct_sr <- mean(diag(solve(diag(dim1) - r*W)*b))
indirect_sr <- mean(colSums((solve(diag(dim1) - r*W)*b)) - diag(solve(diag(dim1) - r*W)*b))
total_sr <- direct_sr + indirect_sr

direct_lr <- mean(diag(solve(diag(dim1) - r*W)*(b/(1-p))))
indirect_lr <- mean(colSums((solve(diag(dim1) - r*W)*(b/(1-p)))) - diag(solve(diag(dim1) - r*W)*(b/(1-p))))
total_lr <- direct_lr + indirect_lr

###Unbalanced

esample<-rownames(as.matrix(lag2[["residuals"]]))
df <- data[esample,]

b <- summary(lag2)$coefficients[3]
r <- summary(lag2)$rho
p <- summary(lag2)$coefficients[2]

##Generate Spatiotemporal FX matrix

df$codeYear <- (df$code_numeric*100)+df$year_numeric

df_i <-  data.frame(df[c("codeYear", "year_numeric", "code_numeric")])
df_i <- df_i[order(df_i$year_numeric,df_i$code_numeric),]
names(df_i) <- c("codeYear_i", "year_numeric_i", "code_numeric_i")

df_j <-  data.frame(df[c("codeYear", "year_numeric", "code_numeric")])
df_j <- df_j[order(df_j$year_numeric,df_j$code_numeric),]
names(df_j) <- c("codeYear_j", "year_numeric_j", "code_numeric_j")

cross <- merge(df_i, df_j, all=TRUE) 

cross$laggedObs <- ifelse((cross$code_numeric_i == cross$code_numeric_j) & (cross$year_numeric_i == cross$year_numeric_j+1), 1,0)

cross <- subset(cross, select=c("codeYear_i", "codeYear_j", "laggedObs"))
 

wide.L <- reshape(cross, 
                  timevar = "codeYear_j",
                  idvar="codeYear_i",
                  direction = "wide") 


df<- df[order(df$year_numeric, df$code_numeric),]

I <- diag(length(esample))
L <-  as.matrix(wide.L[,-1])
Wnt <- as.matrix(w2/rowSums(w2))

st_mult <- solve(I - Wnt*r - L*p)
I_Zbeta <- st_mult*b

##Account for unbalanced structure

shock <- 1970
df1 <- df[df$year >= shock,]


yr_list <- unique(df1$year)[unique(df1$year) >= shock]
t <- length(yr_list)

dim0 <- as.numeric(length(which(df$year < shock))) + 1
#dim1 <- as.numeric(length(which(df$year == shock)))
#n <- dim1 - dim0

df1<- df1 %>% group_by(code_numeric) %>%
  mutate(count = n())

df1$nomissing <- ifelse(df1$count == t, 1, 0)
df1_full <- df1[df1$nomissing == 1,]
units_full <- unique(df1_full$code_numeric)
n <- length(units_full)

#A <- df$code_numeric[which(df$year  ==  shock)] 
#B <- df$code_numeric[which(df$year   >  shock)]
#as.integer(B %in% A)

I_Zbeta_PS <- I_Zbeta[(dim0):dim(I_Zbeta)[1],(dim0):dim(I_Zbeta)[2]]
full_samp <- as.vector(as.integer(df1$code_numeric %in% units_full))

fx_plus <- cbind(I_Zbeta_PS,full_samp)
fx_plus <- rbind(fx_plus,c(full_samp,0))
fx_reduced <- fx_plus[fx_plus[,length(full_samp)+1] == 1,fx_plus[length(full_samp)+1,] == 1]

d_fx_lr = matrix(NA, nrow=t, ncol=n)

for(i in 1:t){ 
  d_fx_lr[i,] <- diag(fx_reduced[(1+(n*(i-1))):(n*i),1:n])
}


direct_lr_unb <- mean(colSums(d_fx_lr))
indirect_lr_unb <- mean(colSums(I_Zbeta_PS[,1:n]) - colSums(d_fx_lr))
total_lr_unb <- mean(colSums(I_Zbeta_PS[,1:n]))

direct_lr 
indirect_lr
total_lr


direct_lr_unb
indirect_lr_unb
total_lr_unb






###Model 2

esample<-rownames(as.matrix(lag6[["residuals"]]))
df <- data[esample,]

shock <- 2000
dim0 <- as.numeric(length(which(df$year < shock)))
dim1 <- as.numeric(length(which(df$year == shock)))

W <- as.matrix(w6/rowSums(w6))
W <- W[(dim0+1):(dim0+dim1),(dim0+1):(dim0+dim1)]

b <- summary(lag6)$coefficients[2]
r <- summary(lag6)$rho

direct_sr <- mean(diag(solve(diag(dim1) - r*W)*b))
indirect_sr <- mean(colSums((solve(diag(dim1) - r*W)*b)) - diag(solve(diag(dim1) - r*W)*b))
total_sr <- direct_sr + indirect_sr

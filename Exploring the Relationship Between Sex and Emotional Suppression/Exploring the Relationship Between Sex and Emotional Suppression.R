getwd()
dirname('38862-0001-Data.rda')
file.exists("38862-0001-Data.rda")

df1 <- load(file='/Users/anneliessealcalde/Desktop/PSC103A/R/38862-0001-Data.rda')
df2 <- load(file='/Users/anneliessealcalde/Desktop/PSC103A/R/36346-0001-Data.rda')

frame1 <- da38862.0001[,] 
frame2 <- da36346.0001[,]

psc103Adata <- merge(frame1, frame2, by = "M2ID", all = FALSE)
library(Hmisc)
library(ggplot2)

# Suppression: continuous variable
continuous = describe(psc103Adata$C5SER)
continuous

continuous = describe(psc103Adata$C5SES)
continuous

# Sex: binary variable
binary = describe(psc103Adata$C1PRSEX.x)
binary

print(paste0("'", levels(psc103Adata$C1PRSEX.x), "'"))

psc103Adata_males = psc103Adata[psc103Adata$C1PRSEX.x %in% c("(1) MALE"), ]  
psc103Adata_females = psc103Adata[psc103Adata$C1PRSEX.x %in% c("(2) FEMALE"), ]  

# age range
age = describe(psc103Adata$C5PAGE)
psc103Adata_C5SES <- psc103Adata[psc103Adata$C5SES == "psc103Adata$C5PAGE", ]

# Calculate the age range for participants in C5SER
age_range_C5SES <- range(C5SES ~ C5PAGE, na.rm = TRUE)

summary(psc103Adata$C5PAGE)
mean(psc103Adata$C5PAGE)

IQR = 72 - 58
lower = 48 - (1.5(14))
upper = 95 + (1.5(14))
lower
upper


# Assuming Q1 is 48 and Q3 is 95
IQR = 72 - 58

# Calculate the lower bound (lower threshold for outliers)
lower = 58 - (1.5 * IQR)

# Calculate the upper bound (upper threshold for outliers)
upper = 72 + (1.5 * IQR)

# Print the lower and upper bounds
print(lower)
print(upper)

# central tendency for scores
mean(psc103Adata$C5SES,na.rm = T)
sd(psc103Adata$C5SES,na.rm = T)

# central tendency for males
mean(psc103Adata_males$C5SES, na.rm = T) 
quantile(psc103Adata_males$C5SES, na.rm = T) 
sd(psc103Adata_males$C5SES, na.rm = T)

# central tendency for females
mean(psc103Adata_females$C5SES, na.rm = T) 
quantile(psc103Adata_females$C5SES, na.rm = T) 
sd(psc103Adata_females$C5SES, na.rm = T)

count_miss = sum(is.na(psc103Adata$C5SES))  # count the number of missing 
count_miss
length(psc103Adata$C5SES) - count_miss

count_miss = sum(is.na(Q1_male <- quantile(psc103Adata_males$C5SES, 0.25, na.rm = TRUE)  # First quartile
Q3_male <- quantile(psc103Adata_males$C5SES, 0.75, na.rm = TRUE)  # Third quartile
IQR_male <- Q3_male - Q1_male  # Interquartile Range

# Compute lower and upper bounds for outliers
lower_bound_male <- Q1_male - 1.5 * IQR_male 
upper_bound_male <- Q3_male + 1.5 * IQR_male 

# Identify outliers
outliers_male <- psc103Adata_males$C5SES[psc103Adata_males$C5SES < lower_bound_male | 
                                         psc103Adata_males$C5SES > upper_bound_male]

# Count the number of outliers
num_outliers_male <- length(outliers_male)))  # count the number of missing 
count_miss
length(psc103Adata$C1PRSEX.x) - count_miss


Q1_male <- quantile(psc103Adata_males$C5SES, 0.25, na.rm = TRUE)  # First quartile
Q3_male <- quantile(psc103Adata_males$C5SES, 0.75, na.rm = TRUE)  # Third quartile
IQR_male <- Q3_male - Q1_male  # Interquartile Range

# Compute lower and upper bounds for outliers
lower_bound_male <- Q1_male - 1.5 * IQR_male 
upper_bound_male <- Q3_male + 1.5 * IQR_male 

# Identify outliers
outliers_male <- psc103Adata$C1PRSEX.x[psc103Adata_males$C5SES < lower_bound_male | 
                                           psc103Adata_males$C5SES > upper_bound_male]

# Count the number of outliers
num_outliers_male <- length(outliers_male)
num_outliers_male 

Q1_female <- quantile(psc103Adata_females$C5SES, 0.25, na.rm = TRUE)  # First quartile
Q3_female <- quantile(psc103Adata_females$C5SES, 0.75, na.rm = TRUE)  # Third quartile
IQR_female <- Q3_female - Q1_female  # Interquartile Range

# Compute lower and upper bounds for outliers
lower_bound_female <- Q1_female - 1.5 * IQR_female 
upper_bound_female <- Q3_female + 1.5 * IQR_female 

# Identify outliers
outliers_female <- psc103Adata$C1PRSEX.x[psc103Adata_females$C5SES < lower_bound_female | 
                                         psc103Adata_females$C5SES > upper_bound_female]

# Count the number of outliers
num_outliers_female <- length(outliers_female)
num_outliers_female 


mean(psc103Adata$C1PRAGE.x)
range(psc103Adata$C1PRAGE.x)


# p-score for males
shapiro.test(psc103Adata_males$C5SES)

# p-score for females
shapiro.test(psc103Adata_females$C5SES)

## Q7:
qqnorm(psc103Adata_males$C5SES,
       main = 'Figure 2a. Normal Q-Q Plot for Male Suppression Score')
qqline(psc103Adata_males$C5SES, col = 'blue')

## Q8:
qqnorm(psc103Adata_females$C5SES,
       main = 'Figure 2b. Normal Q-Q Plot for Female Suppression Score')
qqline(psc103Adata_males$C5SES, col = 'red')

# t test
#t.test(psc103Adata_males$C5SES,
      # psc103Adata_females$C5SES,
      # alternative = "no difference", 
      # var.equal = TRUE)

t.test(C5SES ~ C1PRSEX.x, data = psc103Adata, 
       alternative = "greater", 
       var.equal = TRUE)


Q1_male <- quantile(psc103Adata_males$C5SES, 0.25, na.rm = TRUE)  # First quartile
Q3_male <- quantile(psc103Adata_males$C5SES, 0.75, na.rm = TRUE)  # Third quartile
IQR_male <- Q3_male - Q1_male  # Interquartile Range

# Compute lower and upper bounds for outliers
lower_bound_male <- Q1_male - 1.5 * IQR_male 
upper_bound_male <- Q3_male + 1.5 * IQR_male 

# Identify outliers
outliers_male <- psc103Adata_males$C5SES[psc103Adata_males$C5SES < lower_bound_male | 
                                           psc103Adata_males$C5SES > upper_bound_male]

# Count the number of outliers
num_outliers_male <- length(outliers_male)

num_outliers


### USE THIS ONE
# Convert data into a single dataframe
df <- data.frame(
  value = c(psc103Adata_males$C5SES, psc103Adata_females$C5SES),
  group = rep(c("Male", "Female"), c(length(psc103Adata_males$C5SES), length(psc103Adata_females$C5SES)))
)

# Create back-to-back histogram
ggplot(df, aes(x = value, fill = group)) +
  geom_histogram(data = subset(df, group == "Male"), aes(y = ..count..), bins = 14, alpha = 0.6, color = "black") +
  geom_histogram(data = subset(df, group == "Female"), aes(y = -..count..), bins = 14, alpha = 0.6, color = "black") +
  scale_y_continuous(limits = c(-15, 15), breaks = seq(-15, 15, by = 5), labels = abs) + 
  scale_x_continuous(breaks = 1:7) + # Ensure y-axis labels are positive
  labs(title = "Suppression Score: Male vs Female",
       x = "Suppression Score", y = "Density") +
  theme_minimal() +
  coord_flip() +
  guides(fill = guide_legend(title = "Sex")) 






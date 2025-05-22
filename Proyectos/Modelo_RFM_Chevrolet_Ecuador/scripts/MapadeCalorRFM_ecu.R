

library(readxl)
library(tidyverse)
library(rfm)
library(gridExtra)
library(readr)
library(ggplot2)
library(dplyr)


View(BaseRFM_ECU)  


options(scipen=999)


base_rfm <- BaseRFM_ECU


tabla_mapa_calor

tabla_mapa_calor <- base_rfm %>% 
  group_by(frecuency_score,recency_score,Recency,frecuency) %>% 
  summarise(monetary = mean(MontoTotal),Clientes=n_distinct(ClientesECU_Id),Total = sum(MontoTotal),Facturas=sum(Ventas)) %>% 
  mutate(Ticket=Total/Facturas)

hp <- function (x) { scales::number_format(accuracy = 1,
                                           big.mark = ".")(x) }
mapa_2<-ggplot(data = tabla_mapa_calor) + 
  geom_tile(aes(x = frecuency,y = Recency, fill = monetary)) + 
  scale_fill_gradientn(limits = c(min(tabla_mapa_calor$monetary),max(tabla_mapa_calor$monetary)), 
                       colours = RColorBrewer::brewer.pal(n = 5,name = "PuBu"), name = "Monto promedio"#,labels = hp
  ) + 
  ggtitle("RFM Mapa de calor") +
  xlab("Frecuencia") + ylab("Meses sin comprar") + 
  theme(plot.title = element_text(hjust = 0.5,size=rel(1))) +
  theme(axis.title.x = element_text(size=rel(1))) +
  theme(axis.title.y = element_text(size=rel(1))) +
  theme(axis.text.x =  element_text(size=rel(1))) +
  theme(axis.text.y =  element_text(size=rel(1)))
mapa_2





#______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________--
#grafica para Recencia

#base_rfm$Recencia<-as.factor(base_rfm$Recencia)
summary(base_rfm$Recencia)


base_rfm[,"Recencia1"] <- cut(base_rfm$Recencia,breaks = c(-0.5,5.5,11.5,17.5,23.5,29.5,35.5,41.5,47.5,53.5,59.5,65.5,71.5),
                           labels = c("1-6","7-12","13-18","19-24","25-30","31-36","37-42","43-48","49-54","55-60","61-66","67-69"))


View(base_rfm %>% filter(Recencia==48))
library(plyr)

dfl1 <- ddply(base_rfm, .(Recencia1), summarize, y=length(Recencia1))
str(dfl1)

ggplot(dfl1,aes(Recencia1,y=y))+geom_bar(stat = "identity",fill = "#666666")+ggtitle("Distribución Recencia")+  labs(x = "Meses", y = "Cantidad de clientes") +  theme(plot.title = element_text(hjust = 0.5,size=rel(3)))+theme(axis.title.x = element_text(size=rel(1))) +
  theme(axis.title.y = element_text(size=rel(1)))+geom_text(aes(label=y), vjust=-1)#+scale_x_discrete(labels = c("OCT","SEP","AGO","JUL","JUN","MAY","ABR","MAR","FEB","ENE","DIC","NOV"))


#______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________--
#grafica para Monto

#base_rfm$Recencia<-as.factor(base_rfm$Recencia)
summary(base_rfm$MontoTotal)
quantile(base_rfm$MontoTotal,seq(0,1,0.1))

base_rfm[,"Monto1"] <- cut(base_rfm$MontoTotal,breaks = c(-0.5,1400000,1600000,1800000,2000000,2500000,3000000,1000000000),
                              labels = c("Menos de 1.4M","1.4M-1.6M","1.6M-1.8M","1.8M-2M","2M-2.5M","2.5M-3M","Más de 3M"))


#View(base_rfm %>% filter(Recencia==48))

dfl1 <- ddply(base_rfm, .(Monto1), summarize, y=length(Monto1))
str(dfl1)

ggplot(dfl1,aes(Monto1,y=y))+geom_bar(stat = "identity",fill = "#99700F")+ggtitle("Distribución Monto")+  labs(x = "Monto", y = "Cantidad de clientes") +  theme(plot.title = element_text(hjust = 0.5,size=rel(3)))+theme(axis.title.x = element_text(size=rel(1))) +
  theme(axis.title.y = element_text(size=rel(1)))+geom_text(aes(label=y), vjust=-1)#+scale_x_discrete(labels = c("OCT","SEP","AGO","JUL","JUN","MAY","ABR","MAR","FEB","ENE","DIC","NOV"))



#______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________--
#grafica para Frecuencia

base_rfm %>% group_by(Entradas_score) %>% summarise(n())






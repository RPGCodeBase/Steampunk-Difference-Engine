
INSERT INTO D0 VALUES (100000,"ALIVE","Беббидж","Чарльз","MALE","1791-12-26","лорд",100001,100002,"седой старик с усами и бородой",NULL,"","события из жизни\nбла-бла");
INSERT INTO D0 VALUES (100001,"RIP","Беббидж","Бенжамин","MALE","1760-02-12","банкир",NULL,NULL,"высокий и статный мужчина",100002,"100000,100003","события из жизни\nбла-бла");
INSERT INTO D0 VALUES (100002,"RIP","Беббидж (Стюарт)","Тип","FEMALE","1770-10-11","из семьи ученых",NULL,NULL,"красавица несмотря на годы",100001,"100000,100003","события из жизни\nбла-бла");
INSERT INTO D0 VALUES (100003,"ALIVE","Родшильд (Беббидж)","Элис","FEMALE","1805-03-16","вдова магната и банкира",100001,100002,"красивая, хоть и в летах",100004,"","события из жизни\nбла-бла");
INSERT INTO D0 VALUES (100004,"RIP","Родшильд","Себастьян","MALE","1795-04-07","магнат и банкир",NULL,NULL,"маленький, корявенький",100003,"","события из жизни\nбла-бла");

INSERT INTO D2 VALUES (200000,100000,NULL,1000.0,"","","особняк в Лондоне, здание Машины различий",10,5,2,1,1,"");
INSERT INTO D2 VALUES (200001,100004,NULL,1000000.0,"","660500,644500","заводы,газеты,параходы",100,100,100,50,50,"");
INSERT INTO D2 VALUES (200002,100004,NULL,5000.0,"","","",0,0,0,0,0,"");
INSERT INTO D2 VALUES (200003,100004,"100000,100004",120000.0,"транзакция1\nтранзакция2","633200,624345,643203","заводы по производству вычислительной техники В Манчестере и Бермингеме",200,300,600,1000,200,"Совместное предприятие Беббиджей-Родшильдов");


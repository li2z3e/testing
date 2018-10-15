Исходные документы:  
[*[SPEC][1] Элементы*](http://example.com/)  
[*[SPEC][11] Виды и классы устройств. Группы элементов*](http://example.com/)  

Specification.  
equipmentProfile.xml file format
====

*Editors: Riabtsev P.*  
*Date: 06-03-2018*  
*Version: 3.4.1*  
----

## Content

[1. Описание параметров устройства (тег **\<equipmentProfile/>**)](#equipmentProfile)  
[2. Описание валов устройства (тег **\<shaft/>**)](#shaft)  
&nbsp;&nbsp;&nbsp;&nbsp;[2.1. Описание подшипников вала (тег **\<bearing/>**)](#bearing)  
[3. Описание соединений устройства (тег **\<connection/>**)](#connection)  
[4. Описание электродвигателя устройства (тег **\<motor/>**)](#motor)  
[5. Описание вентиляторов устройства (тег **\<fan/>**)](#fan)  
[6. Описание групп элементов устройства (тег **\<group/>**)](#group)  
[7. Description examples](#description_examples)
___

## <a name="equipmentProfile">1. Описание параметров устройства (тег **\<equipmentProfile/>**)</a>

&emsp;Параметры устройства заносятся в тег **\<equipmentProfile/>** файла equipmentProfile.xml (далее файл). Все параметры записываются в двойных кавычках (см. [Пример 1](#description_1)).  
&emsp;Тег **\<equipmentProfile/>** содержит атрибуты *standard*, *name*, *version*, *id*, *equipmentName*, *equipmentClass*, *equipmentPower*, *equipmentSupport*, *description* и теги **\<shaft/>**, **\<connection/>**, **\<motor/>**, **\<fan/>**, **\<group/>**.

| Name of the field              | Description |
|--------------------------------|-------------|
| *equipmentDataPoints*          | Номера всех точек съема в схеме. |
| *standard*                     | Признак стандартного профиля устройства (для стандартного профиля – `true`). Пример: *standard*="`true`".  |
| *name*                         | Название профиля устройства. Пример: *name*="`standard`". |
| *version*                      | Версия формата файла. Пример: *version*="`3.3.0`". |
| *id*                           | Идентификационный номер файла, уникален для каждого описываемого файла и модификаций. (состоит из восьми десятичных цифр от 0 до 9). Пример: *id*="`12345678`". |
| *equipmentName*                | Название устройства. Пример: *equipmentName*="`exampleStend`". |
| *equipmentClass*               | Вид и класс устройства. Параметры разделяются двоеточием: вид устройства записывается до двоеточия, класс – после. Если класс устройства отсутствует или неизвестен, то записывается только вид. Пример: *equipmentClass*="`turbine:steam`". |
| *equipmentPower*               | Выходная мощность устройства, кВт. Пример: *equipmentPower*="`300`". |
| *equipmentSupport*             | Степень жесткости опоры (жесткие - `rigid`, податливые - `flexible`). Пример: *equipmentSupport*="`flexible`". |
| *description*                  | Описание файла. |
| &nbsp;&nbsp;**\<shaft/>**      | Описания валов устройства. |
| &nbsp;&nbsp;**\<connection/>** | Описания соединений элементов в устройстве. |
| &nbsp;&nbsp;**\<motor/>**      | Описание электродвигателя устройства. |
| &nbsp;&nbsp;**\<fan/>**        | Описание вентиляторов устройства. |
| &nbsp;&nbsp;**\<group/>**      | Описание групп элементов устройства. |

&nbsp;

## <a name="shaft">2. Описание валов устройства (тег **\<shaft/>**)</a>

&emsp;Вал устройства описывается в теге **\<shaft/>**, вложенном в тег **\<equipmentProfile/>**. Если нужно указать несколько валов, то для каждого вала необходимо создать отдельный тег **\<shaft/>**.  
&emsp;Тег **\<shaft/>** включает атрибуты *mainShaft*, *speedCollection*, *schemeName*, *elementProcessingEnable*, *classType*, *equipmentDataPoint*, *imagePositionIndex*, *imageX*, *imageY*, *imageWidth*, *imageHeight*, *imageSlopeDegree* и тег **\<bearing/>**.

| Name of the field           | Description |
|-----------------------------|-------------|
| *mainShaft*                 | Признак основного вала устройства (для основного вала – `true`). Данный атрибут указывается только для основного вала устройства. Пример: *mainShaft*="`true`". |
| *speedCollection*           | Скорости вращения вала, оборотов в минуту. Пример: *speedCollection*="`1000`". |
| *schemeName*                | Название элемента согласно с кинематической схемой. Пример: *schemeName*="`shaft001`". |
| *elementProcessingEnable*   | Разрешить/запретить анализа элемента (разрешить – `1`, запретить – `0`). Пример: *elementProcessingEnable*="`1`". |
| *classType*                 | Класс и тип элемента. Параметры разделяются двоеточием: класс записывается до двоеточия, тип – после. Если типизация элемента отсутствует, то записывается только класс. Пример: *classType*="`shaft`". |
| *group*                     | Название группы, в которую входит элемент. Номер группы указывается через знак нижнего подчеркивания. Если элемент не входит ни в одну из групп, то указывается пустое поле. Примеры: *group*="`windTurbineRotor_001`", *group*="". |
| *equipmentDataPoint*        | Ближайшие точки снятия данных. Если точек несколько, то каждая точка указывается через запятую. Примеры: *equipmentDataPoint*="`1`", *equipmentDataPoint*="`1,3`". |
| *imagePositionIndex*        | Номер элемента на кинематической схеме. Пример: *imagePositionIndex*="`2`". |
| *imageX*                    | Координата центральной точки элемента по оси X на кинематической схеме, пикселей. Пример: *imageX*="`595`". |
| *imageY*                    | Координата центральной точки элемента по оси Y на кинематической схеме, пикселей. Пример: *imageY*="`315`". |
| *imageWidth*                | Ширина эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageWidth*="`1104`". |
| *imageHeight*               | Высота эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageHeight*="`41`". |
| *imageSlopeDegree*          | Угол наклона элемента на кинематической схеме, градусов. Пример: *imageSlopeDegree*="`0`". |
| &nbsp;&nbsp;**\<bearing/>** | Описание подшипника вала. |

&nbsp;

## <a name="bearing">2.1. Описание подшипников вала (тег **\<bearing/>**)</a>

&emsp;Подшипники вала описываются в теге **\<bearing/>**, вложенном в тег **\<shaft/>** вала, к которому относятся. Если нужно указать несколько подшипников, то для каждого подшипника необходимо в теге **\<shaft/>** создать отдельный тег **\<bearing/>**.  
&emsp;Тег **\<bearing/>** включает атрибуты *supporting*, *schemeName*, *elementProcessingEnable*, *classType*, *equipmentDataPoint*, *model*, *imagePositionIndex*, *imageX*, *imageY*, *imageWidth*, *imageHeight*, *imageSlopeDegree*.  
&emsp;При описании подшипника качения (*classType*="`rollingBearing`") в теге **\<bearing/>** дополнительно указываются атрибуты *Nb*, *Bd*, *Pd*, *angle*.

| Name of the field         | Description |
|---------------------------|-------------|
| *supporting*              | Признак основного вала устройства (для основного вала – `true`). Данный атрибут указывается только для основного вала устройства. Пример: *supporting*="`true`". |
| *schemeName*              | Название элемента согласно с кинематической схемой. Пример: *schemeName*="`bearing001`". |
| *elementProcessingEnable* | Разрешить/запретить анализа элемента (разрешить – `1`, запретить – `0`). Пример: *elementProcessingEnable*="`1`". |
| *classType*               | Класс и тип элемента. Параметры разделяются двоеточием: класс записывается до двоеточия, тип – после. Если типизация элемента отсутствует, то записывается только класс. Пример: *classType*="`rollingBearing:deepGrooveBallBearing`". |
| *group*                   | Название группы, в которую входит элемент. Номер группы указывается через знак нижнего подчеркивания. Если элемент не входит ни в одну из групп, то указывается пустое поле. Примеры: *group*="`windTurbineRotor_001`", *group*="". |
| *equipmentDataPoint*      | Ближайшие точки снятия данных. Если точек несколько, то каждая точка указывается через запятую. Примеры: *equipmentDataPoint*="`1`", *equipmentDataPoint*="`1,3`". |
| *model*                   | Модель подшипника. Пример: *model*="`6205`". |
| *Nb*                      | Количество тел качения (Number of balls or rollers) подшипника качения. Пример: *Nb*="`11`". |
| *Bd*                      | Диаметра тела качения (Ball or roller diameter) подшипника качения. Пример: *Bd*="`7.925`". |
| *Pd*                      | Диаметр сепаратора (Pitch diameter) подшипника качения. Пример: *Pd*="`39`". |
| *angle*                   | Угол контакта тел качения подшипника качения, градусов. Пример: *angle*="`0`". |
| *imagePositionIndex*      | Номер элемента на кинематической схеме. Пример: *imagePositionIndex*="`2`". |
| *imageX*                  | Координата центральной точки элемента по оси X на кинематической схеме, пикселей. Пример: *imageX*="`595`". |
| *imageY*                  | Координата центральной точки элемента по оси Y на кинематической схеме, пикселей. Пример: *imageY*="`315`". |
| *imageWidth*              | Ширина эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageWidth*="`1104`". |
| *imageHeight*             | Высота эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageHeight*="`41`". |
| *imageSlopeDegree*        | Угол наклона элемента на кинематической схеме, градусов. Пример: *imageSlopeDegree*="`0`". |

&emsp;Теги *Bd* и *Pd* нужно указывать в одинаковых единицах измерения.  
&emsp;При описании подшипника скольжения (*classType*="`plainBearing`") в теге **\<bearing/>** не указывается дополнительные атрибуты. Структура повторяет подшипник качения, за исключением атрибутов *Nb*, *Bd*, *Pd*, *angle* (при описании подшипника не указываются).

&nbsp;

## <a name="connection">3. Описание соединений устройства (тег **\<connection/>**)</a>

&emsp;Соединения элементов в устройстве описывается в теге **\<connection/>**, вложенном в тег **\<equipmentProfile/>**. Если нужно указать несколько соединения элементов, то для каждого соединения необходимо создать отдельный тег **\<connection/>**.  
&emsp;Тег **\<connection/>** включает атрибуты *schemeName*, *elementProcessingEnable*, *classType*, *equipmentDataPoint*, *imagePositionIndex*, *imageX*, *imageY*, *imageWidth*, *imageHeight*, *imageSlopeDegree* и 2 тега: **\<shaft/>**, **\<shaft/>**; **\<shaft/>**, **\<motor/>** или **\<shaft/>**, **\<fan/>** (зависит от соединяемых элементов).  
&emsp;При описании гладкого ремня (*classType*="`smoothBelt`") в теге **\<connection/>** дополнительно указываются атрибут *beltLength*.  
&emsp;При описании зубчатого ремня (*classType*="`toothedBelt`") в теге **\<connection/>** дополнительно указываются атрибуты *beltLength*, *teethNumber*.  
&emsp;При описании планетарного редуктора (*classType*="`planetaryStageGearbox`") в теге **\<connection/>** дополнительно указываются атрибуты *teethNumberRingGear*.  

| Name of the field         | Description |
|---------------------------|-------------|
| *schemeName*              | Название элемента согласно с кинематической схемой. Пример: *schemeName*="`gearing001`". |
| *elementProcessingEnable* | Разрешить/запретить анализа элемента (разрешить – `1`, запретить – `0`). Пример: *elementProcessingEnable*="`1`". |
| *classType*               | Класс и тип элемента. Параметры разделяются двоеточием: класс записывается до двоеточия, тип – после. Если типизация элемента отсутствует, то записывается только класс. Примеры: *classType*="`gearing`" – соединение с помощью зубчатой передачи; *classType*="`smoothBelt`" – соединение с помощью гладкого ремня. |
| *group*                   | Название группы, в которую входит элемент. Номер группы указывается через знак нижнего подчеркивания. Если элемент не входит ни в одну из групп, то указывается пустое поле. Примеры: *group*="`windTurbineRotor_001`", *group*="". |
| *equipmentDataPoint*      | Ближайшие точки снятия данных. Если точек несколько, то каждая точка указывается через запятую. Примеры: *equipmentDataPoint*="`1`", *equipmentDataPoint*="`1,3`". |
| *beltLength*              | Длина гладкого/зубчатого ремня. Пример: *beltLength*="`800`".  |
| *teethNumber*             | Количество зубьев на зубчатом ремне. Пример: *teethNumber*="`100`". |
| *imagePositionIndex*      | Номер элемента на кинематической схеме. Пример: *imagePositionIndex*="`2`". |
| *imageX*                  | Координата центральной точки элемента по оси X на кинематической схеме, пикселей. Пример: *imageX*="`595`". |
| *imageY*                  | Координата центральной точки элемента по оси Y на кинематической схеме, пикселей. Пример: *imageY*="`315`". |
| *imageWidth*              | Ширина эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageWidth*="`1104`". |
| *imageHeight*             | Высота эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageHeight*="`41`". |
| *imageSlopeDegree*        | Угол наклона элемента на кинематической схеме, градусов. Пример: *imageSlopeDegree*="`0`". |
| &nbsp;&nbsp;**\<shaft/>** | Описание параметров соединенного вала. |
| &nbsp;&nbsp;**\<motor/>** | Описание параметров соединенного электродвигателя. |
| &nbsp;&nbsp;**\<fan/>**   | Описание параметров соединенного вентилятора. |

&emsp;При соединении с помощью зубчатой передачи теги **\<shaft/>**, **\<motor/>** и **\<fan/>**, вложенные в тег **\<connection/>**, включают атрибуты *schemeName*, *teethNumber* (см. [Пример 2](#description_2), [Пример 3](#description_3)).

| Name of the field | Description |
|-------------------|-------------|
| *schemeName*      | Название соединяемого элемента согласно с кинематической схемой. Примеры: *schemeName*="`shaft002`"; *schemeName*="`motor001`". |
| *teethNumber*     | Количество зубьев шестерни, установленной на соединяемый элемент. Пример: *teethNumber*="`28`". |

&emsp;При соединении с помощью ременной передачи теги **\<shaft/>**, **\<motor/>** и **\<fan/>**, вложенные в тег **\<connection/>**, включают атрибуты *schemeName*, *sheaveDiameter* (см. [Пример 4](#description_4), [Пример 5](#description_5)).

| Name of the field | Description |
|-------------------|-------------|
| *schemeName*      | Название соединяемого элемента согласно с кинематической схемой. Примеры: *schemeName*="`shaft002`"; *schemeName*="`motor001`". |
| *sheaveDiameter*  | Диаметр шкива, установленного на соединяемый элемент. Пример: *sheaveDiameter*="`200`". |

&emsp;Теги *beltLength* и *sheaveDiameter* нужно указывать в одинаковых единицах измерения.

&emsp;При соединении с помощью планетарного редуктора теги **\<shaft/>**, **\<motor/>** и **\<fan/>**, вложенные в тег **\<connection/>**, включают атрибуты *schemeName*, *teethNumber*, а тег элемента, соединенного через сателлиты, содержит атрибут *planetWheelNumber* (см. [Пример 6](#description_6), [Пример 7](#description_7)).

| Name of the field   | Description |
|---------------------|-------------|
| *schemeName*        | Название соединяемого элемента согласно с кинематической схемой. Примеры: *schemeName*="`shaft002`"; *schemeName*="`motor001`". |
| *teethNumber*       | Количество зубьев шестерни или одной сателлиты, установленной на соединяемый элемент. Пример: *teethNumber*="`28`". |
| *planetWheelNumber* | Количество сателлит на соединяемом элементе. |

&emsp;При соединении с помощью муфты теги **\<shaft/>**, **\<motor/>** и **\<fan/>**, вложенные в тег **\<connection/>**, включают атрибут *schemeName* (см. [Пример 8](#description_8), [Пример 9](#description_9)).

| Name of the field | Description |
|-------------------|-------------|
| *schemeName*      | Название соединяемого элемента согласно с кинематической схемой. Примеры: *schemeName*="`shaft002`"; *schemeName*="`motor001`". |

&emsp;При соединении с помощью скрытого соединения теги **\<shaft/>**, **\<motor/>** и **\<fan/>**, вложенные в тег **\<connection/>**, включают атрибуты *schemeName*, *gearRatio* (см. [Пример 10](#description_10)).

| Name of the field | Description |
|-------------------|-------------|
| *schemeName*      | Название соединяемого элемента согласно с кинематической схемой. Примеры: *schemeName*="`shaft002`"; *schemeName*="`motor001`". |
| *gearRatio*       | Передаточное число соединяемого элемента (эквивалентно количеству зубьев шестерни при соединении с помощью зубчатой передачи). Пример: *gearRatio*="`1.34`". |

&nbsp;

## <a name="motor">4. Описание электродвигателя устройства (тег **\<motor/>**)</a>

&emsp;Электродвигатель устройства описывается в теге **\<motor/>**, вложенном в тег **\<equipmentProfile/>**.  
&emsp;Тег **\<motor/>** включает атрибуты *schemeName*, *elementProcessingEnable*, *classType*, *equipmentDataPoint*, *model*, *lineFrequency*, *barsNumber*, *polePairsNumber*, *imagePositionIndex*, *imageX*, *imageY*, *imageWidth*, *imageHeight*, *imageSlopeDegree* и тег **\<joint/>**.  
&emsp;При описании асинхронного электродвигателя (*classType*="`inductionMotor`") в теге **\<motor/>** дополнительно указываются атрибуты *barsNumber* и *polePairsNumber*.  
&emsp;При описании синхронного электродвигателя (*classType*="`synchronousMotor`") в теге **\<motor/>** дополнительно указываются атрибут *coilsNumber*.  
&emsp;При описании электродвигателя постоянного тока (*classType*="`directCurrentMotor`") в теге **\<motor/>** дополнительно указываются атрибуты *collectorPlatesNumber*, *armatureTeethNumber*, *rectifierType*.  

| Name of the field         | Description |
|---------------------------|-------------|
| *schemeName*              | Название элемента согласно с кинематической схемой. Пример: *schemeName*="`motor001`". |
| *elementProcessingEnable* | Разрешить/запретить анализа элемента (разрешить – `1`, запретить – `0`). Пример: *elementProcessingEnable*="`1`". |
| *classType*               | Класс и тип элемента. Параметры разделяются двоеточием: класс записывается до двоеточия, тип – после. Если типизация элемента отсутствует, то записывается только класс. Пример: *classType*="`inductionMotor`". |
| *group*                   | Название группы, в которую входит элемент. Номер группы указывается через знак нижнего подчеркивания. Если элемент не входит ни в одну из групп, то указывается пустое поле. Примеры: *group*="`windTurbineRotor_001`", *group*="". |
| *equipmentDataPoint*      | Ближайшие точки снятия данных. Если точек несколько, то каждая точка указывается через запятую. Примеры: *equipmentDataPoint*="`1`", *equipmentDataPoint*="`1,3`". |
| *model*                   | Модель электродвигателя. Пример: *model*="`АИР80B6`". |
| *lineFrequency*           | Линейная частота на входе электродвигателя, Гц. Пример: *lineFrequency*="`32.61`". |
| *barsNumber*              | Количество стержней ротора асинхронного электродвигателя. Пример: *barsNumber*="`22`". |
| *polePairsNumber*         | Количество пар полюсов асинхронного электродвигателя, электродвигателя постоянного тока. Пример: *polePairsNumber*="`3`". |
| *coilsNumber*             | Количество обмоток статора синхронного электродвигателя. Пример: *coilsNumber*="`22`". |
| *collectorPlatesNumber*   | Количество пластин коллектора электродвигателя постоянного тока. Пример: *collectorPlatesNumber*="`1`". |
| *armatureTeethNumber*     | Количество зубьев якоря электродвигателя постоянного тока. Пример: *armatureTeethNumber*="`2`". |
| *rectifierType *          | Тип волнового выпрямителя электродвигателя постоянного тока (`full-wave`, `half-wave`). Если тип выпрямителя неизвестен, то указывается пустой атрибут. Пример: *rectifierType*="`full-wave`". |
| *imagePositionIndex*      | Номер элемента на кинематической схеме. Пример: *imagePositionIndex*="`2`". |
| *imageX*                  | Координата центральной точки элемента по оси X на кинематической схеме, пикселей. Пример: *imageX*="`595`". |
| *imageY*                  | Координата центральной точки элемента по оси Y на кинематической схеме, пикселей. Пример: *imageY*="`315`". |
| *imageWidth*              | Ширина эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageWidth*="`1104`". |
| *imageHeight*             | Высота эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageHeight*="`41`". |
| *imageSlopeDegree*        | Угол наклона элемента на кинематической схеме, градусов. Пример: *imageSlopeDegree*="`0`". |
| &nbsp;&nbsp;**\<joint/>** | Соединение электродвигателя с элементами устройства. |

&emsp;Тег **\<joint/>** включает атрибут *jointElementSchemeName* – название элемента, соединенного с электродвигателем. При прямом соединении электродвигателя и вала в данном атрибуте указывается название вала. Пример записи: *jointElementSchemeName*="`shaft001`". При соединении электродвигателя и вала с помощью соединительных элементов (**\<connection/>**) в данном атрибуте указывается название соединения и создается тег **\<connection/>** (см. Описание соединений устройства). Пример записи: *jointElementSchemeName*="`gearing002`".  

&nbsp;

## <a name="fan">5. Описание вентиляторов устройства (тег **\<fan/>**)</a>

&emsp;Вентилятор устройства описывается в теге **\<fan/>**, вложенном в тег **\<equipmentProfile/>**. Если нужно указать несколько вентиляторов, то для каждого вентилятора необходимо создать отдельный тег **\<fan/>**.  
&emsp;Тег **\<fan/>** включает атрибуты *schemeName*, *elementProcessingEnable*, *classType*, *equipmentDataPoint*, *model*, *bladesNumber*, *imagePositionIndex*, *imageX*, *imageY*, *imageWidth*, *imageHeight*, *imageSlopeDegree* и тег **\<joint/>**.  

| Name of the field         | Description |
|---------------------------|-------------|
| *schemeName*              | Название элемента согласно с кинематической схемой. Пример: *schemeName*="`fan001`". |
| *elementProcessingEnable* | Разрешить/запретить анализа элемента (разрешить – `1`, запретить – `0`). Пример: *elementProcessingEnable*="`1`". |
| *classType*               | Класс и тип элемента. Параметры разделяются двоеточием: класс записывается до двоеточия, тип – после. Если типизация элемента отсутствует, то записывается только класс. Пример: *classType*="`fan`". |
| *group*                   | Название группы, в которую входит элемент. Номер группы указывается через знак нижнего подчеркивания. Если элемент не входит ни в одну из групп, то указывается пустое поле. Примеры: *group*="`windTurbineRotor_001`", *group*="". |
| *equipmentDataPoint*      | Ближайшие точки снятия данных. Если точек несколько, то каждая точка указывается через запятую. Примеры: *equipmentDataPoint*="`1`", *equipmentDataPoint*="`1,3`". |
| *model*                   | Модель вентилятора. Пример: *model*="`ВР120-28`". |
| *bladesNumber*            | Количество лопастей (лезвий) вентилятора. Пример: *model*="`16`". |
| *imagePositionIndex*      | Номер элемента на кинематической схеме. Пример: *imagePositionIndex*="`2`". |
| *imageX*                  | Координата центральной точки элемента по оси X на кинематической схеме, пикселей. Пример: *imageX*="`595`". |
| *imageY*                  | Координата центральной точки элемента по оси Y на кинематической схеме, пикселей. Пример: *imageY*="`315`". |
| *imageWidth*              | Ширина эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageWidth*="`1104`". |
| *imageHeight*             | Высота эллипса, описанного вокруг элемента на кинематической схеме, пикселей. Пример: *imageHeight*="`41`". |
| *imageSlopeDegree*        | Угол наклона элемента на кинематической схеме, градусов. Пример: *imageSlopeDegree*="`0`". |
| &nbsp;&nbsp;**\<joint/>** | Соединение вентилятора с элементами устройства. |

&emsp;Тег **\<joint/>** включает атрибут *jointElementSchemeName* – название элемента, соединенного с вентилятором. При прямом соединении вентилятора и вала в данном атрибуте указывается название вала. Пример записи: *jointElementSchemeName*="`shaft001`". При соединении вентилятора и вала с помощью соединительных элементов (**\<connection/>**) в данном атрибуте указывается название соединения и создается тег **\<connection/>** (см. Описание соединений устройства). Пример записи: *jointElementSchemeName*="`gearing002`".

&nbsp;

## <a name="group">6. Описание групп элементов устройства (тег **\<group/>**)</a>

&emsp;Группа элементов устройства описывается в теге **\<group/>**, вложенном в тег **\<equipmentProfile/>**.  
&emsp;Тег **\<group/>** включает основной атрибут *name* и дополнительные атрибуты *shaftHeight*, *machineAngle*, *bearingHousing*, *pumpCategory* в зависимости от вида и класса устройства (см. [SPEC][11] Виды и классы устройств. Группы элементов).  

| Name of the field | Description |
|-------------------|-------------|
| *name*            | Название группы элементов. Пример: *name*="`hydraulicTurbineRotor _001`". |
| *shaftHeight*     | Высота оси вращения вала согласно ISO 10816-3:2009(E), мм. Указывается для групп всех устройств. Пример: *shaftHeight*="`315`". |
| *machineAngle*    | Угол расположения вала устройства (горизонтальный – `horizontal`, вертикальный – `vertical`) согласно ISO 10816-5:2000(E). Указывается для групп следующих устройств: гидравлические турбины, насосы на насосных станциях. Пример: *machineAngle*="`horizontal`". |
| *bearingHousing*  | Опоры корпусов подшипников (фундамент – `foundation`, корпус – `casing`) согласно ISO 10816-5:2000(E). Указывается для групп следующих устройств: гидравлические турбины, насосы на насосных станциях. Пример: *bearingHousing*="`foundation`". |
| *pumpCategory*    | Категория динамического насоса согласно ISO 10816-7:2009(E) (`1`, `2`). Пример: *pumpCategory*="`1`". |

&nbsp;

## <a name="description_examples">7. Description examples</a>  

### <a name="description_1">Пример 1. Описания кинематической схемы устройств</a>

&emsp;Устройство состоит из двух валов, пяти подшипников, электродвигателя. Валы между собой соединены с помощью зубчатой передачи, электродвигатель установлен на основной вал.  

```
<?xml version="1.0" encoding="UTF-8"?>
<equipmentProfile standard="true" name="standard" version="3.3.0" equipmentName="exampleStend" equipmentClass="motor" equipmentPower="300" equipmentSupport="flexible" description="The place to describe the equipment profile">
    <shaft mainShaft="true" speedCollection="600" schemeName="shaft001" elementProcessingEnable="1" classType="shaft" group="" equipmentDataPoint="1" imagePositionIndex="2" imageX="595" imageY="315" imageWidth="1104" imageHeight="41" imageSlopeDegree="0">
        <bearing supporting="true" schemeName="bearing001" elementProcessingEnable="1" classType="rollingBearing:deepGrooveBallBearing" group="" equipmentDataPoint="1" model="6205" Nb="9" Bd="7.925" Pd="39" angle="0" imagePositionIndex="1" imageX="146" imageY="315" imageWidth="207" imageHeight="83" imageSlopeDegree="0"/>
        <bearing supporting="true" schemeName="bearing002" elementProcessingEnable="1" classType="rollingBearing:deepGrooveBallBearing" group="" equipmentDataPoint="1" model="6205" Nb="9" Bd="7.925" Pd="39" angle="0" imagePositionIndex="4" imageX="698" imageY="315" imageWidth="207" imageHeight="83" imageSlopeDegree="0"/>
        <bearing schemeName="bearing003" elementProcessingEnable="1" classType="rollingBearing:deepGrooveBallBearing" group="" equipmentDataPoint="1" model="6213" Nb="10" Bd="16.6624" Pd="92.5" angle="0" imagePositionIndex="5" imageX="905" imageY="315" imageWidth="207" imageHeight="83" imageSlopeDegree="0"/>
    </shaft>
    
    <shaft schemeName="shaft002" elementProcessingEnable="1" classType="shaft" group="" equipmentDataPoint="2" imagePositionIndex="7" imageX="1150" imageY="440" imageWidth="690" imageHeight="41" imageSlopeDegree="60">
        <bearing supporting="true" schemeName="bearing004" elementProcessingEnable="1" classType="rollingBearing:sphericalRollerBearing" group="" equipmentDataPoint="2" model="23032 CC/W33" Nb="27" Bd="20" Pd="203.062" angle="0" imagePositionIndex="6" imageX="1029" imageY="649" imageWidth="207" imageHeight="83" imageSlopeDegree="60"/>
        <bearing supporting="true" schemeName="bearing005" elementProcessingEnable="1" classType="rollingBearing:sphericalRollerBearing" group="" equipmentDataPoint="2" model="30234 X/DF" Nb="21" Bd="35.7" Pd="240.676" angle="0" imagePositionIndex="9" imageX="1271" imageY="231" imageWidth="207" imageHeight="83" imageSlopeDegree="60"/>
    </shaft>
    
    <connection schemeName="gearing001" elementProcessingEnable="1" classType="gearing" group="" equipmentDataPoint="1, 2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
        <shaft schemeName="shaft001" teethNumber="19"/>
        <shaft schemeName="shaft002" teethNumber="28"/>
    </connection>
    
    <motor schemeName="motor001" elementProcessingEnable="1" classType="inductionMotor" group="" equipmentDataPoint="1" model="АИР80B6" lineFrequency="32.61, 48.92" barsNumber="22" polePairsNumber="3" imagePositionIndex="3" imageX="422" imageY="315" imageWidth="345" imageHeight="207" imageSlopeDegree="0">
        <joint jointElementSchemeName="shaft001"/>
    </motor>
</equipmentProfile>

```

&nbsp;

### <a name="description_2">Пример 2. Описание соединения двух валов с помощью зубчатой передачи</a>

```
<connection schemeName="gearing001" elementProcessingEnable="1" classType="gearing" group="" equipmentDataPoint="1,2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" teethNumber="19"/>
	<shaft schemeName="shaft002" teethNumber="28"/>
</connection>
```

&nbsp;

### <a name="description_3">Пример 3. Описание соединения электродвигателя и вала с помощью зубчатой передачи</a>

```
<connection schemeName="gearing002" elementProcessingEnable="1" classType="gearing" group="" equipmentDataPoint="1,2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" teethNumber="19"/>
	<motor schemeName="motor001" teethNumber="28"/>
</connection>
```

&nbsp;

### <a name="description_4">Пример 4. Описание соединения двух валов с помощью ременной передачи (гладкий ремень)</a>

```
<connection schemeName="belting001" elementProcessingEnable="1" classType="smoothBelt" group="" equipmentDataPoint="1,2" beltLength="800" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" sheaveDiameter="60"/>
	<shaft schemeName="shaft002" sheaveDiameter="100"/>
</connection>
```

&nbsp;

### <a name="description_5">Пример 5. Описание соединения вентилятора и вала с помощью ременной передачи (зубчатый ремень)</a>

```
<connection schemeName="belting002" elementProcessingEnable="1" classType="toothedBelt" group="" equipmentDataPoint="1,2" beltLength="800" teethNumber="100" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" sheaveDiameter="100"/>
	<fan schemeName="fan001" sheaveDiameter="60"/>
</connection>
```

&nbsp;

### <a name="description_6">Пример 6. Описание соединения двух валов с помощью планетарного редуктора (первый вал соединен через сателлиты)</a>

```
<connection schemeName="gearing001" elementProcessingEnable="1" classType="planetaryStageGearbox" group="" equipmentDataPoint="1,2" teethNumberRingGear="60" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" teethNumber="10" planetWheelNumber="3"/>
	<shaft schemeName="shaft002" teethNumber="40"/>
</connection>
```

&nbsp;

### <a name="description_7">Пример 7. Описание соединения вентилятора и вала с помощью планетарного редуктора (вал соединен через сателлиты)в</a>

```
<connection schemeName="gearing002" elementProcessingEnable="1" classType="planetaryStageGearbox" group="" equipmentDataPoint="1,2" teethNumberRingGear="60" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" teethNumber="10" planetWheelNumber="3"/>
	<fan schemeName="fan001" teethNumber="40"/>
</connection>
```

&nbsp;

### <a name="description_8">Пример 8. Описание соединения двух валов с помощью муфты</a>

```
<connection schemeName="coupling001" elementProcessingEnable="1" classType="coupling" group="" equipmentDataPoint="1,2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001"/>
	<shaft schemeName="shaft002"/>
</connection>
```

&nbsp;

### <a name="description_9">Пример 9. Описание соединения электродвигателя и вала с помощью муфты</a>

```
<connection schemeName="coupling002" elementProcessingEnable="1" classType="coupling" group="" equipmentDataPoint="1,2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001"/>
	<motor schemeName="motor001"/>
</connection>
```

&nbsp;

### <a name="description_10">Пример 10. Описание соединения двух валов с помощью скрытого соединения</a>

```
<connection schemeName="connection001" elementProcessingEnable="1" classType="hidden" group="" equipmentDataPoint="1,2" imagePositionIndex="8" imageX="1133" imageY="366" imageWidth="380" imageHeight="242" imageSlopeDegree="-60">
	<shaft schemeName="shaft001" gearRatio="1"/>
	<motor schemeName="motor001" gearRatio="1.5"/>
</connection>
```
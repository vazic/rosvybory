# РосВыборы

Проект логически состоит из двух основных частей:

- Форма для создания заявок наблюдателей:

 - Сама форма, на DSL Formtastic'a, валидация через модель заявки.

 - Результат заполнения формы - заявка, `UserApp`.
 

- Админка, позволяющая просматривать созданные заявки, искать среди них нужные с помощью фильтров, создавать на их основе записи о людях, и т.п, по ТЗ.
 - Реализация админки - на основе [Active Admin](https://github.com/gregbell/active_admin/tree/rails4)

### Важно при деплое

Нужно не забыть обратить внимание на пользователя админки!

В новой БД, развёрнутой через load и seed, такого пользователя не будет, его проще всего будет создать через консоль рельсов, 

`AdminUser.create!(:email => 'admin@example.com', :password => 'password', :password_confirmation => 'password')`, с другими данными, разумеется.

В продакшене хорошо бы ещё как-то озаботиться безопасностью в плане доступа к админке, т.к. в таком варианте, как я понимаю, вполне возможен брутфорс. Может быть пока имеет смысл дополнительно установить http-аутентификацию на location админки на уровне веб-сервера.


### Некоторые пояснения, если кто-то возьмётся дорабатывать

Модель заявок, `UserApp`:

Сейчас хранение статусов волотнёра (бывшие статусы `previous_statuses`, и те, на которые он согласен в будущем `desired_statuses`) сделано через битовые маски, в БД хранится один integer для каждого набора статусов (всего получается, соответственно, 3), в котором битовым ИЛИ собраны все отмеченные пользователем статусы. В модели динамически генерируются методы определения значения для каждого значения статуса, например, для статуса `STATUS_OBSERVER => "observer"` - методы `can_be_observer`, `was_observer`, вместе с сеттерами, методы используются для формы и для подробного вывода данных в доп. полях csv.

Такой подход имеет свои плюсы, однако из-за того, что у Arel нет предикатов для бинарных операций (чтобы можно было через него сделать вот такое `UserApp.where('previous_statuses & ? > 0', STATUS_OBSERVER | STATUS_MOBILE)`), возникли сложности с фильтрами по этим статусам в админке, которая использует для запросов Ransack, которому, в свою очередь, нужны предикаты Arel. Как создать новый предикат для Arel я пока не разобрался, но, похоже, если кто-то сходу не знает, как это сделать, дальше на это нет смысла тратить время, как-то слишком сложно получается.

Я вижу пока такие варианты выхода: 

- попробовать хранить статусы в постгресовских массивах - но тут тоже надо будет разбираться, как выполнять поиск по ним через Ransack и Arel
- Просто зафигачить по boolean полю на каждый вариант статуса (с именами, с которомы сейчас генерятся методы, генерацию методов убрать) - очень тупо и некрасиво, но зато точно будет работать.
- Попробовать хранить статусы как какие-то символьные коды в строковой переменной в БД, тогда поиск можно будет делать последовательностью обычных 'LIKE', с которыми Ransack замечательно работает. Я пока вижу этот вариант как лучший выход, но времени попробовать его реализовать уже нет.

В плане индексов и скорости поиска, я так понимаю, особой разницы не будет, т.к. ни один из вариантов всё равно адекватно не проиндексировать, кроме, разве что, варианта с постгрес-массивами, и то сомнительно.

Заявки, по идее, после создания не должны редактироваться (кроме служебных полей) или удаляться, поэтому у контроллера отключены соответствующие действия. В админке в дальнейшем также будет отключено удаление и полное редактирование, нужно будет реализовать и дать там доступ к более специализированным действиям, таких как изменение статуса заявки или привязка к человеку.

Кроме полей, заполняемых пользователями, при создании также в заявку сохраняются ip и user agent заявителя, для дальнейшего отлова ботов или ручных накруток.

Админка:

Доступна по пути `/control`

Сейчас там добавлены фильры по отдельным полям, поиск по текстовым нужно будет объединить, оставив одну строку для поиска. Я вижу следующие варианты:

 - в заявке создать служебное текстовое поле, куда, после коннектации класть все текстовые поля, по которым ожидается поиск, искать через 'LIKE'. Нужно как-то реализовать поиск без учета регистра, или через операторы поиска, или через предварительную обработку как этого поля, так и поисковой строки. Надо учесть, что вариант может быть крайне медленным.
 - делать поиск по всем нужным полям и сцеплять результаты через OR. В этом случае будет вряд ли сильно быстрее + возможно будет сложно реализовать сам фильтр в админке.
 - попробовать подключить полнотекстовый поиск постгреса (или даже сторонний, типа thinking_sphinx, но это создаёт отдельную мороку с администрированием, установкой сфинкса и т.п.). Из плюсов - это точно будет быстро, но я пока затрудняюсь сказать, насколько сложно будет интегрировать это с Ransack и, соответственно, админкой.


Сейчас отключены удобные списки select2 в админке, (закомментировано содержимое assets/javascript/active_admin/select2), т.к. при первом открытии списка почему-то происходит прокрутка экрана на центр таблицы, что очень мешает. Если с этим разобраться, можно включать.
  
В админке ещё много чего нужно кастомизировать - я пока занимался настройкой index'а для заявок, кроме доведения до ума фильтров для этой страницы также надо будет сделать кастомные действия для заявок (с возможностью групповой обработки), оптимизировать дизайн, попробовав уместить все на экране без прокрутки вбок, возможно, добавить какую-то цветовую индикацию или scope по статусам заявок. 
Где-то (вероятно, на странице просмотра заявки) нужно будет реализовать отображение списка найденых похожих заявок (совпадения по ip или ФИО, или ещё что-нибудь такое) и механизмы групповой их обработки.

Модель для людей и, соответственно, все связанные с этим механизмы, типа утверждения заявки, ещё не созданы.

Ну, и нужны тесты...



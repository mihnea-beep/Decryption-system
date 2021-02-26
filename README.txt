----------------------------------------------

## Prezentarea generala a solutiei:

	Am gandit separat implementarea fiecarui task, tratand modulele ca pe niste sisteme de tip black-box (acestea putand fi testate individual, in afara de decryption_top).
	In continuare sunt prezentate pe scurt modulele si logica din spatele acestora, iar in -- Explicarea portiunilor complexe sunt elaborate ideile pe care le-am considerat importante din anumite module.

## Modulele:

- decryption_regfile:	 Acesta functioneaza ca un banc de registre obisnuit. In functie de semnalele read/write se face cate un
tip de acces, care consta in scrierea/citirea de date la o adresa (valida sau nu). Daca aceasta nu exista, se ridica un semnal de eroare,
iar in caz contrar, se realizeaza scrierea/citirea. Semnalul done se activeaza doar in timpul citirii/scrierii, indiferent daca adresa este una valida sau nu.
Acesta este dezactivat dupa realizarea scrierii/citirii. In mod similar, eroarea se dezactiveaza pe urmatorul front pozitiv al ceasului, dupa ce a fost activata.

- caesar_decryption: Decriptarea cezar presupune scaderea unei valori (key) din numarul ce reprezinta fiecare caracter
in cod ASCII, pentru fiecare caracter al textului criptat.

- scytale_decryption: In mare, decriptarea scytale presupune plecarea de la primul caracter din cuvantul criptat si deplasarea
la dreapta cu key_N caractere pentru selectarea urmatorului caracter in cuvantul decriptat. Cand se ajunge la un index
inexistent/se depaseste numarul total de caractere, se pleaca de la al doilea caracter si procedura se repeta.
Nu a fost nevoie sa utilizez cheia key_M.

- zigzag_decryption: Decriptarea zigzag se realizeaza in mod diferit, in functie de cheia primita. Am folosit algoritmi separati ce
se aplica in functie de cheie si de numarul de caractere.

- demux: Modulul demux depinde de 2 ceasuri, clk_sys si clk_mst, dintre care clk_mst este de 4 ori mai lent.
Astfel, am impartit logica in 2 structuri always.

- mux: Modulul mux functioneaza ca un multiplexor obisnuit, tinandu-se cont de un singur ceas si de reset.

- decryption_top:

	Modulul decryption_top conecteaza toate modulele anterioare, precum si semnalele de busy corespunzatoare fiecarui modul de decriptare (printr-un OR gate cu 3 intrari).

----------------------------------------------

## Explicarea portiunilor complexe

	In general, pentru a manipula grupuri specifice de biti din variabilele folosite la fiecare task, am folosit operatorul +: din bonusul primei teme.
	Pentru a realiza imparitiri, am folosit algoritmul de impartire cu rest din modulul division al primei teme.

- scytale_decryption: - Disclaimer: Am adaugat o conditie suplimentara pentru scytale_decryption la task 3, deoarece semnalul
valid_i era mai lung decat sirul de caractere trimise, anume: if(valid_i == 1 && data_i != 0), pentru a asigura faptul ca nu mai
sunt luate in considerare caracterele nule, chiar daca valid_i ramane activ.

			 In cadrul decriptarii scytale, am folosit urmatoarea logica:

- Datele se citesc atat timp cat semnalul valid_input este activ, iar datele nu sunt nule. Cat timp literele sunt diferite de caracterul
special 0xFA, sunt numarate caracterele, stocate datele (in variabila full_text) si actulaizata pozitia, adica deplasarea prin full_text
(asemanator cu numarul de caractere, dar unitatea de adunat este marimea unui caracter). La intalnirea caracterului special, 0xFA, busy este
activat, din numarul de caractere se scade 1 (pentru ca la ultima citire, numarul de caractere este cu 1 mai mare decat numarul real), iar semnalul
de "trigger", end_of_word, care semnalizeaza faptul ca "pachetul" de date a ajuns la final, este activat. Dupa caracterul special, datele care
vin sunt nule. Este verificat trigger-ul, iar acesta se reseteaza si declanseaza activarea lui valid_output pe urmatorul front pozitiv, prima litera
din data_output si incrementarea unor variabile de tip contor folosite in decriptare (pozitia curenta in cuvantul textul decriptat, indicii
corespunzatori literelor ce urmeaza sa fie decriptate).

- Decriptarea se realizeaza astfel: Odata activat trigger-ul, map_letter (numarul corespunzator indexului urmatorului caracter ce urmeaza sa fie afisat
- indexul "maparii" pentru decriptare) se incrementeaza cu key_N, crt_letter (indexul corespunzator caracterului folosit dupa depasirea numarului
total de caractere in urma deplasarilor - algoritmul descris in --- Prezentarea generala a solutiei) creste cu 1 pentru urmatoarea folosire,
si current_char este incrementat cu 1 (caracterul curent in decriptare). Se afiseaza primul caracter care coincide cu primul caracter din textul criptat.

- Cat timp caracterul curent este mai mic decat numarul de caractere, se calculeaza noua pozitie (map_letter), daca aceasta nu depaseste numarul
de caractere, se afiseaza urmatorul caracter si se incrementeaza caracterul curen. Daca acest index depaseste numarul de caractere, se pleaca de la urmatorul caracter
(pentru prima depasire, se pleaca de la al doilea caracter), se incrementeaza caracterul curent, crt_letter (pentru urmatoarea depasire)
si noul map_letter (crt_letter + key_N). Cand indexul caracterului curent este egal cu numarul de caractere, acesta se mai incrementeaza o singura data.
Pe urmatorul front pozitiv, indexul caracterului curent depaseste numarul de caractere, iar data_output, si semnalele busy si valid_output sunt puse pe 0.

Cand busy si valid_output sunt 0, sunt resetate si variabilele utilizate in cadrul decriptarii.

- zigzag_decryption: Similar cu decriptarea scytale, datele pentru decriptare sunt stocate intr-o variabila de tip reg, enc_data,
iar numarul de caractere, nof_chars este incrementat cu 1, atat timp cat semnalul de valid_input este activ, iar data_input nu este
nul si cat timp nu se intalneste caracterul special, 0xFA. La intalnirea acestuia, semnalul de trigger, end_of_transmission se activeaza,
iar din numarul de caractere (mai mare cu 1) se scade 1. Trigger-ul declanseaza activarea lui busy pe urmatorul front al ceasului.
Cat timp busy este activ, se activeaza valid_output si, in functie de cheia primita si de numarul de caractere (daca acesta este par
sau impar), se realizeaza decriptarea si impartirea numarului de caractere, la cheia de decriptare, catul fiind pus in variabila Q.

Pentru cheia 2 si numar par de caractere, algoritmul general este urmatorul: Se pleaca de la primul caracter. Urmatorul caracter
din cuvantul decriptat se afla la pozitionat la dreapta pe pozitia index_caracter_1 + (nr_caractere / 2). Procedura se repeta
pana la completarea cuvantului. Indexul trebuie sa nu depaseasca valoarea catului - 1.

Am folosit o variabila numita low a carui nume care semnifica "coborarea" in reprezentarea grafica a decriptarii. Concret, cand
semnalul low este inactiv, in data_output este pus caracterul aflat la indexul curent (initial 0) in textul criptat, iar cand
acesta este activ, in data_output se pune caracterul aflat la indexul shiftat la dreapta cu catul impartirii numarului de caractere la
cheie (adica 2). Dupa fiecare pas, se incrementeaza current_char.

Cand current_char depaseste numarul de caractere, semnalele se reseteaza. Cand numarul de caractere este impar, indexul nu trebuie sa
depaseasca valoarea catului.


Pentru cheia 3, am gasit o regula care functioneaza pentru anumite cuvinte criptate complet, iar pentru altele partial, din cate se
observa pe checker. Spre exemplu, reprezentand scrierea pe diagonala pentru ANAAREMERESIPERE si notand de la stanga la dreapta incepand
cu indexul 0, fiecare caracter, se obtine urmatoarea secventa:

0 4 12 5 1 6 13 7 2 8 14 9 3 10 15 11

Se obtin urmatoarele cicluri sub forma de "matrice":

[0 4 12 5]
[1 6 13 7]
[2 8 14 9]
[3 10 15 11]

Fiind vorba de cheie 3, intr-un ciclu vor fi maxim 4 elemente. Numarul de linii este egal cu numarul de ciclii.
Am observat ca diferenta dintre elementele din prima "coloana" si cele de pe a treia coloana este constanta si diferenta dintre elementele
de pe linii este constanta. De exemplu, linia_2 - linia_1 = 1 2 1 2
												sau
										linia_3 - linia_2 = 1 2 1 2

Astfel, daca se poate stabili o regula pentru scrierea primei linii (a indecsilor din primul ciclu, se poate stabili un algoritm pe baza caruia
se scriu si ceilalti indecsi).

Am considerat prima coloana ca fiind cea a indecsilor de inceput:

idx_i idx_j
	  a  b c
0   | 4 12 5
1   | 6 13 7
2   | 8 14 9
3   | 10 15 11

Vom avea 2 "for-uri"

idx_i se va afla intre 0 : nr_ciclii - 1
idx_j se va afla intre 1 si key

Pentru primul caz, idx_i este 0 - idx_j este 0: data_output va fi chiar caracterul cu index idx_i din textul criptat

data_output va fi chiar caracterul cu index idx_i

Pentru cazurile in care idx_j este 1, 2, 3 cei 3 idx_j corespunzatori se calculeaza in felul urmator

a_idx <= a_idx + nr_ciclii
b_idx <= a_idx + 2 * nr_ciclii
c_idx <= a_idx + 1

Pe data_output se va pune caracterul din textul criptat de pe indexul idx_i + nr_ciclii (pentru j = 1),
a_idx + 2 * nr_ciclii (j = 2) si a_idx + 1 (j = 3)

Urmatoarele 3 cazuri sunt identice, deoarece respecta regula prezentata mai sus (diferenta constanta), deci vom avea

a_idx <= a_idx + 2, j = 1
b_idx <= b_idx + 1, j = 2
c_idx <= c_idx + 2, j = 3

Pentru j = 0, caracterul curent va fi cel de pe pozitia idx_i (din indecsii de inceput).

Regula decripteaza complet doar anumite input-uri.


## demux: In structura care depinde de master, always @(posedge clk_mst):

	- Daca valid_input este activ, se stocheaza datele primite (stored_data) si se activeaza semnalul de valid_output pentru
select-ul corespunzator. Daca valid_input este 0, atunci valid_output devine 0 pentru   toate semnalele, iar stored_data
devine 0. (ca un reset in functie de input).

	In structura care depinde de sistem, always @(posedge clk_sys):

	- Am folosit mai multe variabile de tip contor pentru a tine cont de numarul de fronturi pozitive ale ceasului clk_sys
si de indexul corespunzator caracterului ce trebuie afisat din stored_data sau data_i. Astfel, transmission_index este un
counter in functie de valoarea caruia se afiseaza caracterul corespunzator pentru iesire, clk_fronts_passed numara fronturile
pozitive ale ceasului de la activarea valid_input, iar timer numara fronturile pozitive incepand cu momentul in care valid_i
devine 0, dupa incheierea transmiterii de date, pentru a reseta counter-ul de fronturi pozitive. Timer-ul timer se reseteaza
singur dupa 4 clk sys. In prev_clk_fronts_passed, se tine minte numarul de fronturi de ceas trecute de pe frontul anterior.
Atunci cand numarul de fronturi curent clk_fronts_passed devine egal cu prev_clk_fronts_passed, adica nu mai este incrementat
dupa transmiterea datelor, timer-ul mentionat mai devreme incepe sa numere.

	- Din cauza faptului ca stocarea datelor depinde de clk_mst, la momentul in care s-au numarat 4 fronturi de clk_sys (0-3),
valoarea variabilei stored_data inca nu s-a actualizat. Modificarea lui data_output (data0/1/2_o) se face in functie de
valoarea din stored_data. In consecinta, pentru a gestiona afisarea primului caracter, am tratat separat cazul in care indexul
de transmitere a datelor este 0 (si numarul de fronturi numarate este 4). In loc de a atribui lui data_output valoarea din stored_data,
data_output ia valoarea primului caracter direct din data_i. Restul caracterelor sunt tratate impreuna, in functie de select.
"Formula" de calcul a bitilor pentru afisat depinde de transmission_index:

		   Bitii:		Index:

		   [24 : 31]	index 0 + 3
		   [16 : 23]	index 1 + 1
		   [8  : 15]	index 2 - 1
		   [0 :   7]	index 3 - 3



## mux: In functie de valoarea semnalului select (0, 1, 2) si de activarea semnalelor de tip valid_input, (valid0/1/2_i),
pe semnalul de iesire data_o se punea valoarea corespunzatoare (respectiv data0/1/2_i), iar valid_o devine activ.
Pentru semnalele valid_input 0, iesirile vor fi 0.

## decryption_top: Selectie biti specifici:

			- select: Din cauza variatiei marimii semnalului select (16 biti in decryption_regfile si 2 biti in demux si mux), am selectat doar bitii 1 si 0 in mux si demux.
			- scytale_key: scytale_key este impartit in 2 semnale de 8 biti pentru cele doua chei (scytale_key[15: 8], scytale_key[7 : 0])

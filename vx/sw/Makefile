# maxhpc: Maxim Vorontsov

PROJECT = maxhpc
SRC = $(wildcard *.cpp)

${PROJECT}: $(SRC)
	g++ -I. $^ -o $@

clean:
	rm ${PROJECT}

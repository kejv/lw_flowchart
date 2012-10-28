Extract information from LoneWolf gamebooks in order to display it in the form
of a graph (flowchart). Visit http://www.projectaon.org to get acquainted with
LoneWolf books and also to get XML source files needed as input for the main program.

Usage:
  mkdir -p graphs
  ./graph.pl 01fftd.xml

This will create two files: graphs/01fftd.dot (the source for graphviz dot program)
and graphs/01fftd.svg (the actual flowchart).
You must have dot installed on your computer and in your PATH. You can get it
here: http://www.graphviz.org.
#! /usr/bin/newlisp

; connect
(set 'socket (net-connect "localhost" 3720))
(if (nil? socket)((println "unable find server")(exit)))

; send random color
(net-send socket (amb "RED\n" "BLUE\n"))
(net-receive socket buf 64 "\n")

; send random setup
(set 'setup (append (join (randomize (explode "BBBBBBM98877766665555444433333222222221F"))) "\n" ) )
(net-send socket setup)
(net-receive socket confirmation 64 "\n")
(if(!= confirmation "OK\n")((println "setup invalid!")(exit)))

(while true (begin 
   ; get opponent move
   (net-receive socket buf 64 "\n")
   (if (= buf "WIN\n") (begin (println "yay! I won!")(exit))
       (= buf "LOSE\n")(begin (println "aww! I lost!")(exit)))

   ; receive board
   (set 'board (array 10 10 '(".") ))
   (dotimes (i 10)
      (net-receive socket buf 64 "\n")
      (dotimes (j 10) (setf (board i j) (buf j))) )
   
   ; find your units and check for movable tiles around it
   (set 'moves '())
   (dotimes (y 10)
     (dotimes (x 10)
       (if (find (board y x) "123456789M")
	   (begin
	     (if (and (> x 0) (find (board y (- x 1)) ".#" )) (push (list x y (- x 1) y) moves))
	     (if (and (< x 9) (find (board y (+ x 1)) ".#" )) (push (list x y (+ x 1) y) moves))
	     (if (and (> y 0) (find (board (- y 1) x) ".#" )) (push (list x y x (- y 1)) moves))
	     (if (and (< y 9) (find (board (+ y 1) x) ".#" )) (push (list x y x (+ y 1)) moves)) ))))

   ; choose randomly, stringify its results and send it over
   (net-send socket (apply
	   (fn(a b c d)
	     (append "MOVE "
		     (nth a "ABCDEFGHIJ")
		     (string (- b 10))
		     " "
		     (nth c "ABCDEFGHIJ")
		     (string (- d 10))
		     "\n"))
	   (first (randomize moves)) ))

   ; get results
   (net-receive socket buf 64 "\n")
   (if (starts-with buf "INVALID")(begin (println "made invalid move!")(exit))) ))

(exit)

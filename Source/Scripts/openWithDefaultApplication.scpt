FasdUAS 1.101.10   ��   ��    k             l     ��  ��    : 4 Copyright (c) 2010-2011, BILD digital GmbH & Co. KG     � 	 	 h   C o p y r i g h t   ( c )   2 0 1 0 - 2 0 1 1 ,   B I L D   d i g i t a l   G m b H   &   C o .   K G   
  
 l     ��  ��      All rights reserved.     �   *   A l l   r i g h t s   r e s e r v e d .      l     ��������  ��  ��        l     ��  ��      BSD License     �      B S D   L i c e n s e      l     ��������  ��  ��        l     ��  ��    I C Redistribution and use in source and binary forms, with or without     �   �   R e d i s t r i b u t i o n   a n d   u s e   i n   s o u r c e   a n d   b i n a r y   f o r m s ,   w i t h   o r   w i t h o u t      l     ��   ��    R L modification, are permitted provided that the following conditions are met:      � ! ! �   m o d i f i c a t i o n ,   a r e   p e r m i t t e d   p r o v i d e d   t h a t   t h e   f o l l o w i n g   c o n d i t i o n s   a r e   m e t :   " # " l     �� $ %��   $ G A	* Redistributions of source code must retain the above copyright    % � & & � 	 *   R e d i s t r i b u t i o n s   o f   s o u r c e   c o d e   m u s t   r e t a i n   t h e   a b o v e   c o p y r i g h t #  ' ( ' l     �� ) *��   ) F @	  notice, this list of conditions and the following disclaimer.    * � + + � 	     n o t i c e ,   t h i s   l i s t   o f   c o n d i t i o n s   a n d   t h e   f o l l o w i n g   d i s c l a i m e r . (  , - , l     �� . /��   . J D	* Redistributions in binary form must reproduce the above copyright    / � 0 0 � 	 *   R e d i s t r i b u t i o n s   i n   b i n a r y   f o r m   m u s t   r e p r o d u c e   t h e   a b o v e   c o p y r i g h t -  1 2 1 l     �� 3 4��   3 L F	  notice, this list of conditions and the following disclaimer in the    4 � 5 5 � 	     n o t i c e ,   t h i s   l i s t   o f   c o n d i t i o n s   a n d   t h e   f o l l o w i n g   d i s c l a i m e r   i n   t h e 2  6 7 6 l     �� 8 9��   8 M G	  documentation and/or other materials provided with the distribution.    9 � : : � 	     d o c u m e n t a t i o n   a n d / o r   o t h e r   m a t e r i a l s   p r o v i d e d   w i t h   t h e   d i s t r i b u t i o n . 7  ; < ; l     �� = >��   = ? 9	* Neither the name of BILD digital GmbH & Co. KG nor the    > � ? ? r 	 *   N e i t h e r   t h e   n a m e   o f   B I L D   d i g i t a l   G m b H   &   C o .   K G   n o r   t h e <  @ A @ l     �� B C��   B M G	  names of its contributors may be used to endorse or promote products    C � D D � 	     n a m e s   o f   i t s   c o n t r i b u t o r s   m a y   b e   u s e d   t o   e n d o r s e   o r   p r o m o t e   p r o d u c t s A  E F E l     �� G H��   G N H	  derived from this software without specific prior written permission.    H � I I � 	     d e r i v e d   f r o m   t h i s   s o f t w a r e   w i t h o u t   s p e c i f i c   p r i o r   w r i t t e n   p e r m i s s i o n . F  J K J l     ��������  ��  ��   K  L M L l     �� N O��   N P J THIS SOFTWARE IS PROVIDED BY BILD digital GmbH & Co. KG ''AS IS'' AND ANY    O � P P �   T H I S   S O F T W A R E   I S   P R O V I D E D   B Y   B I L D   d i g i t a l   G m b H   &   C o .   K G   ' ' A S   I S ' '   A N D   A N Y M  Q R Q l     �� S T��   S P J EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED    T � U U �   E X P R E S S   O R   I M P L I E D   W A R R A N T I E S ,   I N C L U D I N G ,   B U T   N O T   L I M I T E D   T O ,   T H E   I M P L I E D R  V W V l     �� X Y��   X M G WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE    Y � Z Z �   W A R R A N T I E S   O F   M E R C H A N T A B I L I T Y   A N D   F I T N E S S   F O R   A   P A R T I C U L A R   P U R P O S E   A R E W  [ \ [ l     �� ] ^��   ] Q K DISCLAIMED. IN NO EVENT SHALL BILD digital GmbH & Co. KG BE LIABLE FOR ANY    ^ � _ _ �   D I S C L A I M E D .   I N   N O   E V E N T   S H A L L   B I L D   d i g i t a l   G m b H   &   C o .   K G   B E   L I A B L E   F O R   A N Y \  ` a ` l     �� b c��   b Q K DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    c � d d �   D I R E C T ,   I N D I R E C T ,   I N C I D E N T A L ,   S P E C I A L ,   E X E M P L A R Y ,   O R   C O N S E Q U E N T I A L   D A M A G E S a  e f e l     �� g h��   g S M (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    h � i i �   ( I N C L U D I N G ,   B U T   N O T   L I M I T E D   T O ,   P R O C U R E M E N T   O F   S U B S T I T U T E   G O O D S   O R   S E R V I C E S ; f  j k j l     �� l m��   l R L LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND    m � n n �   L O S S   O F   U S E ,   D A T A ,   O R   P R O F I T S ;   O R   B U S I N E S S   I N T E R R U P T I O N )   H O W E V E R   C A U S E D   A N D k  o p o l     �� q r��   q Q K ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    r � s s �   O N   A N Y   T H E O R Y   O F   L I A B I L I T Y ,   W H E T H E R   I N   C O N T R A C T ,   S T R I C T   L I A B I L I T Y ,   O R   T O R T p  t u t l     �� v w��   v T N (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    w � x x �   ( I N C L U D I N G   N E G L I G E N C E   O R   O T H E R W I S E )   A R I S I N G   I N   A N Y   W A Y   O U T   O F   T H E   U S E   O F   T H I S u  y z y l     �� { |��   { C = SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.    | � } } z   S O F T W A R E ,   E V E N   I F   A D V I S E D   O F   T H E   P O S S I B I L I T Y   O F   S U C H   D A M A G E . z  ~  ~ l     ��������  ��  ��     � � � l     ��������  ��  ��   �  � � � i      � � � I     �� � �
�� .facofgetnull���     alis � o      ���� 0 	my_folder   � �� ���
�� 
flst � o      ���� 0 	the_files  ��   � Y     ' ��� � ��� � k    " � �  � � � l   ��������  ��  ��   �  � � � r     � � � l    ����� � n     � � � 4    �� �
�� 
cobj � o    ���� 0 i   � o    ���� 0 	the_files  ��  ��   � o      ���� 0 	this_file   �  � � � l   ��������  ��  ��   �  � � � l    �� � ���   � , & display dialog (this_file as string)     � � � � L   d i s p l a y   d i a l o g   ( t h i s _ f i l e   a s   s t r i n g )   �  � � � l   ��������  ��  ��   �  � � � O      � � � I   �� ���
�� .aevtodocnull  �    alis � o    ���� 0 	this_file  ��   � m     � ��                                                                                  sevs  alis    �  Macintosh HD               �)��H+    +System Events.app                                               +��8CW        ����  	                CoreServices    �)å      �8'7      +   �   �  :Macintosh HD:System:Library:CoreServices:System Events.app  $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��   �  ��� � l  ! !��������  ��  ��  ��  �� 0 i   � m    ����  � n    
 � � � m    	��
�� 
nmbr � n    � � � 2   ��
�� 
cobj � o    ���� 0 	the_files  ��   �  ��� � l     ��������  ��  ��  ��       �� � ���   � ��
�� .facofgetnull���     alis � �� ����� � ���
�� .facofgetnull���     alis�� 0 	my_folder  �� ������
�� 
flst�� 0 	the_files  ��   � ���������� 0 	my_folder  �� 0 	the_files  �� 0 i  �� 0 	this_file   � ���� ���
�� 
cobj
�� 
nmbr
�� .aevtodocnull  �    alis�� ( &k��-�,Ekh ��/E�O� �j UOP[OY�� ascr  ��ޭ
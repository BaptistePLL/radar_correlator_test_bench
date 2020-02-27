
--*********************************************************************************
--		PILE GENERIQUE (un paramètre permet de déterminer la taille de la pile)
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pile is generic( N_pile: integer := 8; N: integer := 8); --cf cours kerhoas généricite
	port( raz, clk, calc, ld : in std_logic;
              d_in : in std_logic_vector ( N-1 downto 0);
              ref : out std_logic_vector (N-1 downto 0));
end pile;

architecture arch_pile of pile is
	type memoire is array(integer range 0 to N_pile -1) of std_logic_vector( N downto 0);
	signal mem: memoire := (others => (others => '0'));
begin
	process(clk)
		begin
		if rising_edge(clk) then
			     if raz = '1' then
          			mem <= (others => (others => '0'));--tableau de données (1 seule dimension)
		      	elsif ld = '1' then
		      	  mem(0) <= d_in;
          			for i in 0 to N-2 loop
          			  mem(1 to N-1) <= mem(0 to N-2);
     			     end loop;
 		     	 elsif calc = '1' then
 		     	   for i in 0 to N-2 loop
               mem(1 to N-1) <= mem(0 to N-2);
    			      end loop;
    			      mem(0) <= mem(N-1);
			     end if;
		end if;
	end process;
	ref <= mem(N-1);
end arch_pile;


--*********************************************************************************
--		MULTIPLIEUR GENERIQUE
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;



-- Id: A.17
--function "*" ( L: UNSIGNED; R: NATURAL) return UNSIGNED;
-- Result subtype: UNSIGNED((L'length+L'length-1) downto 0).
-- Result: Multiplies an UNSIGNED vector, L, with a non-negative 
--         INTEGER, R. R is converted to an UNSIGNED vector of 
--         SIZE L'length before multiplication.

entity multiplieur is generic(N_entree: integer := 7;  N_sortie: integer := 15); 
  port(E1,E2 : in std_logic_vector(N_entree downto 0);
 		   S : out std_logic_vector(N_sortie downto 0));
end multiplieur;
 
architecture arch_multiplieur of multiplieur is
begin
    S <= std_logic_vector(signed(E1)*signed(E2));
end arch_multiplieur;


--*********************************************************************************
--		ADDITIONNEUR GENERIQUE
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity additionneur is port(E1,E2 : in std_logic_vector(20 downto 0);
            	   	    S : out std_logic_vector(20 downto 0));
end additionneur;
 
architecture arch_additionneur of additionneur is
begin
    S <= std_logic_vector(signed(E1)+signed(E2));--ou unsigned ? est ce que la sortie est forcément signed comme pour le mutiplieur?
               
end arch_additionneur;
--*********************************************************************************
--		REGISTRE GENERIQUE : taille de l'entrée et taille de la sortie paramétrables
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity registre is generic(taille_entree : integer:=16;
        		   taille_sortie : integer:=21);
port(clk, raz, ld : in std_logic;
     data_in: in std_logic_vector(taille_entree-1 downto 0);
     data_out: out std_logic_vector(taille_sortie-1 downto 0));
end registre;

architecture arch_registre of registre is
  signal sortie : std_logic_vector(taille_sortie-1 downto 0);
begin
	process(clk)
	 	begin
	 	if rising_edge(clk) then
	   		if raz='1' then data_out <= (others => '0');
		 	 elsif ld='1' then
		 	   sortie(taille_entree-1 downto 0) <= data_in;
		 	   sortie(taille_sortie-1 downto taille_entree) <= (others => data_in(taille_entree-1));
			 end if;
		end if;
 	end process;
 	data_out <= sortie;
end arch_registre;  

--*********************************************************************************
--		SEQUENCEUR du CORRELATEUR
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity sequenceur is port(clk,reset : in std_logic;
    			  ref,clke  : in std_logic;
    			  cnt : in std_logic_vector(7 downto 0);
    			  raz_pile_rec, raz_pile_ref, raz_reg_pdt, raz_reg_sum, ld_pile_rec, ld_pile_ref, ld_reg_pdt, 
			  calc, ld_reg_sum, raz_cnt, en_cnt : out std_logic);
end sequenceur;
 
architecture arch_sequenceur of sequenceur is
type etat is (RAZ,E_0,E_1,E_2,E_3,E_4,Attente_0,Attente_1,Attente_2,Attente_3);
signal etat_cr, etat_sv : etat;
begin
	process(clk, reset)
	begin
		if reset = '1' then etat_cr <= RAZ;
		elsif rising_edge(clk) then etat_cr <= etat_sv;
		end if;
	end process;
 	
	process(clk,cnt,clke,ref,etat_cr)
    	begin
    		raz_pile_rec <= '1';
   		raz_pile_ref <= '1';
    		raz_reg_pdt <= '1';
    		raz_reg_sum <= '1';
    		raz_cnt<='1';
    		ld_pile_ref <= '0';
    		ld_pile_rec <= '0';
    		ld_reg_pdt <= '0';
    		ld_reg_sum <= '0';
    		calc <= '0';
    		en_cnt<='0';
    		etat_sv <= etat_cr;
     
    		case etat_cr is
        		when RAZ => if ref='1' and clke = '1' then etat_sv <= E_0; end if;
        
       		 	when E_0 => etat_sv <= Attente_0;
                		ld_pile_ref <= '1'; 
 
        		when E_1 => etat_sv <= E_2;
                		ld_pile_rec <= '1';
                		raz_reg_pdt <= '1';
                		raz_reg_sum <= '1';
                		raz_cnt <= '1';  
                 
        		when E_2 => if cnt = "00101100" then etat_sv <= E_3; --compte arrivé à 44
        			    elsif cnt < "00101100"  then etat_sv <= E_2; end if; --compte pas à44
                		en_cnt <= '1';
                		ld_reg_pdt <= '1';
                		ld_reg_sum <= '1';
                		calc <= '1';
                
        		when E_3 => etat_sv <= E_4;
                		ld_reg_pdt <= '1';
                		ld_reg_sum <= '1'; 
                 
        		when E_4 => if clke = '0' then etat_sv <= Attente_2; 
        			    elsif clke = '1' then etat_sv <= Attente_3; end if;
                		ld_reg_sum <= '1';
                
        		when Attente_0 => if clke='0' then etat_sv <= Attente_1;
        				  elsif clke ='1' then etat_sv <= Attente_0; end if;
        
        		when Attente_1 => if clke='0' then etat_sv <= Attente_1;
       	 				  elsif clke ='1' and ref = '1' then etat_sv <= E_0; 
        				  elsif clke ='1' and ref = '0' then etat_sv <= E_1; end if;

        		when Attente_2 => if clke='0' then etat_sv <= Attente_2;
        				  elsif clke ='1' and ref = '1' then etat_sv <= E_0;
        				  elsif ref = '0' and clke = '1' then etat_sv <= E_1; end if;
        
        		when Attente_3 => if clke='1' then etat_sv <= Attente_3;
        				  elsif clke ='0' then etat_sv <= Attente_2; end if;
       
          
                
    		end case;   
	end process;
end arch_sequenceur;

--*********************************************************************************
--		COMPTEUR DU SEQUENCEUR
--**********************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compteur is generic(N : integer:=8);
port(clk,raz : in std_logic;
     en : in std_logic;
     cnt : out std_logic_vector(N-1 downto 0));
end compteur;
 
architecture arch_compteur of compteur is
signal count : unsigned (N-1 downto 0);
begin
    	process(clk)
		begin
		if raz='1' then count <= (others => '0');
		elsif en = '1' then count <= count + 1 ;
		elsif count="00101101" then count <= (others => '0'); --comptage terminé, on est a 45
		end if;
	end process;
	cnt <= std_logic_vector(count); 
end arch_compteur;


--*********************************************************************************
--*********************************************************************************
--	                              CORRELATEUR
--*********************************************************************************
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.stimul_pack.all;
use work.all;
   
      
entity correlateur is generic(N: integer:=8;
			   taille_sortie: integer:=21;
	                   N_pile: integer:=44;
			   taille_entree: integer :=16); 
port( ref, reset, clk, clke : in std_logic;
    	 d_in :  in std_logic_vector(7 downto 0);
         correll :  out std_logic_vector(20 downto 0));
end correlateur;
  
architecture arch_correlateur of correlateur is
  signal ref_p		: std_logic_vector(N-1 downto 0);
  signal rec_p		: std_logic_vector(N-1 downto 0);
  signal mult		: std_logic_vector(taille_entree-1 downto 0);
  signal add_1		: std_logic_vector(taille_sortie-1 downto 0);
  signal add_2		: std_logic_vector(taille_sortie-1 downto 0);
  signal acc		: std_logic_vector(taille_sortie-1 downto 0);
  signal CALC		: std_logic;
  signal raz_pile_rec	: std_logic;
  signal ld_pile_rec	: std_logic;
  signal raz_pile_ref	: std_logic;
  signal ld_pile_ref	: std_logic;
  signal raz_reg_pdt	: std_logic;
  signal ld_reg_pdt	: std_logic;
  signal raz_reg_sum	: std_logic;
  signal ld_reg_sum	: std_logic;
  signal raz_reg_out	: std_logic;
  signal ld_reg_out	: std_logic;
  signal raz_cnt	: std_logic;
  signal en_cnt	: std_logic;
  signal cnt	: std_logic_vector(N-1 downto 0);
begin

pile_ref: entity pile port map(
                    	clk => clk,
                    	raz => raz_pile_ref,
                    	ld => ld_pile_ref,
                    	calc => calc,
                    	d_in  => d_in,
                    	ref => ref_p);

pile_rec: entity pile port map(
                    	clk => clk,
                    	raz => raz_pile_rec,
                    	ld => ld_pile_rec,
                    	calc => calc,
                    	d_in => d_in,
                    	ref => rec_p);

mutt: entity multiplieur port map(
                    	E1 => ref_p,
                    	E2 => rec_p,
                    	S  => mult);
                
reg_pdt: entity registre port map(
                    	clk => clk,
                    	raz => raz_reg_pdt,
                    	ld => ld_reg_pdt,
                    	data_in => mult,
                    	data_out => add_1);

reg_sum: entity registre generic map(taille_entree=>taille_sortie, taille_sortie=>taille_sortie) port map(
                    	clk => clk,
                    	raz => raz_reg_sum,
                    	ld => ld_reg_sum,
                   	data_in => acc,
                    	data_out => add_2);

			correll <= add_2;

add: entity additionneur port map(
                    	E1 => add_1,
                    	E2 => add_2,
                    	S  => acc);

compt: entity compteur port map(
                    	raz => raz_cnt,
                    	en => en_cnt,
                    	cnt => cnt,
                    	clk => clk);

seq: entity sequenceur port map(
                    	ref => ref,
                    	clke => clke,
                    	reset => reset,
                    	clk => clk,
                    	calc => calc,
                    	raz_pile_rec => raz_pile_rec,
                    	raz_pile_ref => raz_pile_ref,
                    	raz_reg_pdt => raz_reg_pdt,
                    	raz_reg_sum => raz_reg_sum,
                    	ld_pile_rec => ld_pile_rec,
                    	ld_pile_ref => ld_pile_ref,
                    	ld_reg_pdt => ld_reg_pdt,
                    	ld_reg_sum => ld_reg_sum,
                    	raz_cnt => raz_cnt,
                    	en_cnt => en_cnt,
                    	cnt  => cnt);

end arch_correlateur; 
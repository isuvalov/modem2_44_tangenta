-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_fun_pkg.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Packages/auk_rs_fun_pkg.vhd,v $
--
-- $Revision: 1.2 $
-- $Date: 2005/08/26 12:05:01 $
-- Check in by  : $Author: admanero $  
--
-- Author       :  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	:  This package contains all (except the memory ones) the functions
--                  that are required to elaborate any RS encoder or decoder from
--                 its primary parameters
--
-- Copyright 1999 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package  auk_rs_fun_pkg  is

constant NO_WARNING: BOOLEAN := FALSE; -- default to emit warnings

Constant M_MAX : NATURAL := 12;
--Constant CHECK_MAX : NATURAL := 50;

Subtype max_vector is Std_Logic_Vector(M_MAX downto 1);

type vector_2D is array(NATURAL RANGE <>) of max_vector;

type std_logic_matrix is array (natural range <>, natural range <>) of std_logic;

type std_logic_cube is array (natural range <>, natural range <>, natural range <>) of std_logic;

type NATURAL_ARRAY is array(NATURAL RANGE <>) of NATURAL;

function LOG2_ceil_table(x: in NATURAL) return NATURAL;

function generate_gf_alpha_to_power (m, irrpol : NATURAL )
																		 return NATURAL_ARRAY;
function generate_gf_index_of_alpha (alpha_to_power: NATURAL_ARRAY )
																		 return NATURAL_ARRAY;

function GFadd (A, B, m : NATURAL)	return NATURAL;

function GFmul (A, B : NATURAL;
								Index_of, alpha_to_power: NATURAL_ARRAY)
								return NATURAL;

function GFmul_can (A, B, m, irrpol : NATURAL)	return NATURAL;

function GFdiv (A, D : NATURAL;
								Index_of, alpha_to_power: NATURAL_ARRAY)
								return NATURAL;

function generate_pol_coeficients (m, check, genstart, rootspace: NATURAL;
																	 Index_of, alpha_to_power: NATURAL_ARRAY)
																	 return NATURAL_ARRAY;

function get_matrix_from_cube(cube_in: std_logic_cube; index : NATURAL)
															return std_logic_matrix;

function gen_all_pol_coefs(check, m, genstart, rootspace, wide : NATURAL;
 												 Index_of, alpha_to_power : NATURAL_ARRAY)
 												return std_logic_cube;

function gen_num_bit_errors(m : NATURAL) return std_logic_matrix;

procedure pla_table(signal invec: in std_logic_vector;
										signal outvec: out std_logic_vector;
										constant table: std_logic_matrix);


function generate_roots(m, check, genstart, rootspace : NATURAL;
											  Index_of, alpha_to_power: NATURAL_ARRAY) return NATURAL_ARRAY;

function make_chain (size, m, rootspace : NATURAL;
										 Index_of, alpha_to_power: NATURAL_ARRAY )
										 return NATURAL_ARRAY;

function make_cont  (size, m, check, rootspace : NATURAL;
										 Index_of, alpha_to_power: NATURAL_ARRAY )
										 return NATURAL_ARRAY;

--function make_cont_exp  (size, m, n, rootspace : NATURAL;
--										 Index_of, alpha_to_power: NATURAL_ARRAY )
--										 return NATURAL_ARRAY;

--function natural_2_m (ARG, SIZE: NATURAL) return Std_Logic_vector;

function Get_max_of_three(param_1, param_2, param_3 : NATURAL) return NATURAL;

function Build_binary_table(n : NATURAL) return std_logic_matrix;

function calc_errs(check : NATURAL; Erasures: STRING)	return NATURAL;

end auk_rs_fun_pkg;


package body  auk_rs_fun_pkg  is


function LOG2_ceil_table(x: in NATURAL) return NATURAL is

  variable result : NATURAL;

begin
	
	if x=1 then
	  result:=0;
	elsif x=2 then
	  result:=1;
	elsif x>2 and x<5 then
	  result:=2;
	elsif x>4 and x<9 then
	  result:=3;
	elsif x>8 and x<17 then
	  result:=4;
	elsif x>16 and x<33 then
	  result:=5;
	elsif x>32 and x<65 then
	  result:=6;
	elsif x>64 and x<129 then
	  result:=7;
	elsif x>128 and x<257 then
	  result:=8;
	elsif x>256 and x<513 then
	  result:=9;
	elsif x>512 and x<1025 then
	  result:=10;
	elsif x>1024 and x<2049 then
	  result:=11;
	elsif x>2048 and x<4097 then
	  result:=12;
	else
	  assert NO_WARNING
          report "RS_functions.LOG2_ceil_table: x out of range"
          severity WARNING;
  end if;
	return result;

end LOG2_ceil_table;

-- this function has to go!!
-- function natural_2_m (ARG, SIZE: NATURAL) return Std_Logic_vector is
    -- variable RESULT: Std_Logic_vector(SIZE downto 1);
    -- variable I_VAL: NATURAL;
  -- begin
    -- I_VAL := arg;
    -- for I in 1 to RESULT'LEFT loop
      -- if (I_VAL mod 2) = 0 then
        -- RESULT(I) := '0';
      -- else RESULT(I) := '1';
      -- end if;
      -- I_VAL := I_VAL/2;
    -- end loop;
    -- if not(I_VAL =0) then
      -- assert NO_WARNING
          -- report "RS_functions.Natural_2_m: vector truncated"
          -- severity WARNING;
    -- end if;
    -- return RESULT;
-- end natural_2_m;

function GFmul_can (A, B, m, irrpol : NATURAL)	return NATURAL is

		variable A_vec : Std_Logic_Vector(m downto 1);
		variable C_vec, B_vec, irp : Std_Logic_Vector(2*m-1 downto 1);
		variable result : NATURAL;

	begin

  	result := 0;
  	irp(2*m-1 downto m-1) :=
			CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => irrpol, SIZE => m+1), SIZE => m+1);
		--natural_2_m(arg => irrpol, size => m+1);
		irp(m-2 downto 1) := (others =>'0');
		A_vec := 
			CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => A, SIZE => m), SIZE => m);
		--natural_2_m(arg => A, size => m);
		B_vec(m downto 1) :=
			CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => B, SIZE => m), SIZE => m);
		--natural_2_m(arg => B, size => m);
		C_vec := (others => '0');
		B_vec(2*m-1 downto m+1) := (others => '0');

		for I in 1 to m loop
			if A_vec(I)='1' then
				C_vec := C_vec xor B_vec;
			end if;
			B_vec(2*m-1 downto 2) := B_vec(2*m-2 downto 1);
			B_vec(1) := '0';
		end loop;
		for I in 2*m-1 downto m+1 loop
			if C_vec(I)='1' then
				C_vec := C_vec xor irp;
			end if;
			irp(2*m-2 downto 1) := irp(2*m-1 downto 2);
			irp(2*m-1) := '0';
		end loop;
		-- Convert to NATURAL
		for I in 1 to m loop
			if C_vec(I)='1' then
				result := result + 2**(I-1);
			end if;
		end loop;
		return result;


--int gfmul (int a, int b)
--{
--
--/* multiplier over GF(2^mm) 			 */
--
--int c = 0,j = 0,cc = 0;
--int pos = 1;
--
--/* expand polynomial products    */
--
--for (j = 0; j<mm; j++)
--	{
--	 if ((a&pos) != 0)
--		{
--		 cc = (b * (int)pow(2,j));
--		 c = c ^ cc;
--		}
--	 pos = pos * 2;
--	}
--
--/* reduce polynomial            */
--
--pos = (int)pow(2,(2*mm-2)); /* for mm = 8, 16384 */
--
--for (j = 2*mm-1; j>mm ; j--)
--	{
--	 if ((c&pos) != 0)
--		{
--		 cc = (mp * (int)pow(2, (j-(mm+1))));
--		 c = c ^ cc;
--		}
--	 pos = pos / 2;
--	}
--
--return c;
--
--}
	
end GFmul_can;

function generate_gf_alpha_to_power (m, irrpol : NATURAL ) return NATURAL_ARRAY is

  Constant  gf_n_max : NATURAL := 2**m-1;
  
	variable  result: NATURAL_ARRAY(gf_n_max downto 0);
	variable  aux: NATURAL;

  begin

	result(0) := 1;
	result(1) := 2;
	aux := 2;
	for I in 2 to gf_n_max loop
		aux := gfmul_can(A => aux, B => 2, m => m, irrpol => irrpol);
		result(I) := aux;
	end loop;
	
	return result;


end generate_gf_alpha_to_power;


function generate_gf_index_of_alpha (alpha_to_power: NATURAL_ARRAY ) return NATURAL_ARRAY is

	-- Constant  gf_n_max : NATURAL := 2**m-1;

	variable  result: NATURAL_ARRAY(alpha_to_power'HIGH downto 0);

	begin
		
		for I in 0 to alpha_to_power'HIGH loop
		  result(alpha_to_power(I)) := I;
		end loop;

	return result;

end generate_gf_index_of_alpha;

function GFadd (A, B, m : NATURAL)	return NATURAL is

		variable A_vec, B_vec, C_vec : Std_Logic_Vector(m downto 1);
		variable result : NATURAL;

	begin

		result := 0;
		A_vec := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => A, SIZE => m), SIZE => m); 
		--natural_2_m(arg => A, size => m);
		B_vec := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => B, SIZE => m), SIZE => m); 
		--natural_2_m(arg => B, size => m);
		C_vec := A_vec xor B_vec;
	-- Convert to NATURAL
		for I in 1 to m loop
			if C_vec(I)='1' then
				result := result + 2**(I-1);
			end if;
		end loop;
		return result;

end GFadd;


function GFmul (A, B : NATURAL; Index_of, alpha_to_power: NATURAL_ARRAY) return NATURAL is

	variable index_of_A, index_of_B, prod, result: NATURAL;

--/* Compute x % NN, where NN is 2**gf_mm - 1,
-- * without a slow divide
-- */
--int modnn(int x)
--{
--	while (x >= gf_nn_max) {
--		x -= gf_nn_max;
--		x = (x >> gf_mm) + (x & gf_nn_max);
--	}
--	return x;
--}/* modnn */


--int gf_mul_tab(int m1, int m2)
--{
--	int m1_i,m2_i,prod_i,result;
--
--	if((m1 == 0) || (m2 == 0)) return(0);
--
--	m1_i = Index_of[m1];
--	m2_i = Index_of[m2];
--	prod_i = modnn(m1_i + m2_i);
--	result = Alpha_to[prod_i];

	begin

		if ((A = 0) or (B = 0)) then
			result := 0;
		else
			index_of_A := Index_of(A);
			index_of_B := Index_of(B);
			prod := (index_of_A + index_of_B) mod (Index_of'HIGH);
			result := alpha_to_power(prod);
		end if;
		  
--	return result;
		return result;
--
--}/* gf_mul_tab */

end GFmul;



function GFdiv (A, D : NATURAL; Index_of, alpha_to_power: NATURAL_ARRAY) return NATURAL is

	variable index_of_A, index_of_D, div, result: NATURAL;

--/* Compute x % NN, where NN is 2**gf_mm - 1,
-- * without a slow divide
-- */
--int modnn(int x)
--{
--	while (x >= gf_nn_max) {
--		x -= gf_nn_max;
--		x = (x >> gf_mm) + (x & gf_nn_max);
--	}
--	return x;
--}/* modnn */


--int gf_div_tab(int m1, int m2)
--{
--	int m1_i,m2_i,div_i,result;
--
--	if((m1 == 0) || (m2 == 0)) return(0);
--
--	m1_i = Index_of[m1];
--	m2_i = Index_of[m2];
--	div_i = modnn(m1_i - m2_i);
--	result = Alpha_to[div_i];

	begin

		if ((A = 0) or (D = 0)) then
			result := 0;
		else
			index_of_A := Index_of(A);
			index_of_D := Index_of(D);
			div := (index_of_A - index_of_D) mod (Index_of'HIGH);
			result := alpha_to_power(div);
		end if;
		  
--	return result;
		return result;
--
--}/* gf_div_tab */

end GFdiv;


function generate_pol_coeficients (m, check, genstart, rootspace: NATURAL;
																	 Index_of, alpha_to_power: NATURAL_ARRAY)
																	 return NATURAL_ARRAY is


-- Notice that the coeficients g0 g1 g2 ... of the generator polynomial are swapped between 
--  the internet version and Martin Langhammer version. In the first one g0 is the lower power term
--  while in ML version g0 is the highest power.
--
-- /* gg(x) = x + a^genstart*/
-- alpha_step = powers[alpha_exp];
-- printf("\n Alpha step is ...%d\n", alpha_step); 
-- gg[0] = 1;
-- roots[0] = 1;
-- gg[1] = powers[(alpha_exp*genstart)%gfmax];
-- roots[1] = powers[(alpha_exp*genstart)%gfmax];
-- printf("\nroot1 = %d\n", roots[1]);
--/*   The polynomial is built by multipliying gg(i-1)(x) by (x + a^(alpha_exp)*(genstart + i)) */
--
-- alpha = powers[(alpha_exp*(genstart+1))%gfmax];
-- roots[2] = powers[(alpha_exp*(genstart+1))%gfmax];
-- printf("root2 = %d\n", roots[2]);
--
-- for (j = 0; j<(r-1); j++)
--	 {
--	  for (p = 1; p<=(j+2); p++)
--		  {
--			ggmul[p] = gfmul(gg[p-1],alpha);
--		  }
--	  for (p = 1; p<=(j+2); p++)
--		  {
--			gg[p] = gg[p] ^ ggmul[p];
--		  }
--	  alpha = gfmul(alpha,alpha_step);
--		roots[j+3]=alpha;
--		printf("root%d = %d\n", j+3, roots[j+3]);
--	 }
-- }
		variable gg, ggmul: NATURAL_ARRAY(check downto 0);
		variable alpha, alpha_step: NATURAL;
		Constant gf_n_max : NATURAL := 2**m-1;

	begin
		alpha_step := alpha_to_power(rootspace);
		gg(0) := 1;
		gg(1) := alpha_to_power((genstart*rootspace) mod gf_n_max);
		alpha := alpha_to_power( (rootspace*(genstart + 1)) mod gf_n_max);
		
		for J in 0 to check-2 loop
		  for p in 1 to J+2 loop
			  ggmul(p) := GFmul(gg(p-1), alpha, Index_of, alpha_to_power);
			end loop;
			for p in 1 to J+2 loop
			  gg(p) := GFadd(A => gg(p), B => ggmul(p), m => m);  -- GFadd: Xor in natural type to be solved
			end loop;
		alpha := GFmul(alpha, alpha_step, Index_of, alpha_to_power);
		end loop;
		
		return gg;

end generate_pol_coeficients;

----------------------


function get_matrix_from_cube(cube_in: std_logic_cube; index : NATURAL)
	return std_logic_matrix is

	variable result : std_logic_matrix(cube_in'range(2), cube_in'range(3));

begin
  	for J in cube_in'range(2) loop
			for k in cube_in'range(3) loop
				result(J,K) := cube_in(index, J, K);
			end loop;
		end loop;

	return result;

end function get_matrix_from_cube;


function gen_all_pol_coefs(check, m, genstart, rootspace, wide : NATURAL;
 												 Index_of, alpha_to_power : NATURAL_ARRAY)
 												return std_logic_cube is
	
	constant two_pow_wide : NATURAL := 2**wide; 
	constant two_pow_m		: NATURAL := 2**m;    
	Constant gf_n_max : NATURAL := 2**m-1;

	variable tmp : Std_Logic_Vector(wide downto 1);
	variable tmp2 : Std_Logic_Vector(m downto 1);
	variable tmp3 : Std_Logic_Vector(m+wide downto 1);

  variable gg, ggmul : NATURAL_ARRAY(two_pow_wide+1 downto 0);
	variable iterate, alpha, alpha_step, in_table : NATURAL;

	variable alphamatrix : std_logic_cube(check downto 1, two_pow_wide downto 1, m+wide downto 1);

begin

  for H in two_pow_wide downto 1 loop
	  iterate := H;
		gg := (others => 0);

		alpha_step := alpha_to_power(rootspace);
		gg(0) := 1;
		gg(1) := alpha_to_power((genstart*rootspace) mod gf_n_max);
		alpha := alpha_to_power( (rootspace*(genstart + 1)) mod gf_n_max);
		
		for J in 0 to iterate-1 loop
		  for p in 1 to J+2 loop
			  ggmul(p) := GFmul(gg(p-1), alpha, Index_of, alpha_to_power);
			end loop;
			for p in 1 to J+2 loop
			  gg(p) := GFadd(A => gg(p), B => ggmul(p), m => m);
			end loop;
		alpha := GFmul(alpha, alpha_step, Index_of, alpha_to_power);
		end loop;
		for K in 1 to check loop
		  in_table := (H+1) mod two_pow_wide;
			tmp := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => in_table, SIZE => wide), SIZE => wide); 
			--natural_2_m(arg => in_table, size => wide);
			if (in_table > 1) and (in_table <= check) then
				tmp2 := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => gg(K), SIZE => m), SIZE => m); 
				--natural_2_m(arg => gg(K), size => m);
			else
				tmp2 := (others => '-');
			end if;
			tmp3 := tmp&tmp2;
			for b in 1 to m+wide loop
				alphamatrix(k, two_pow_wide-H+1, b) := tmp3(b);
			end loop;
		end loop;
	end loop;
	
return alphamatrix;


--------------

-- int j,p;
-- int alpha;
-- int ggmul[41];
--
-- for (h = r; h>0; h--)
--	{
--	 iterate = h;
--
--	 for (k = 0; k<=40; k++)
--	  {
--		gg[k] = 0;
--	  }
--
------ genvar
--   My version of the algorithm to make it clear, 
-- /* instead of 3m fill in first 2 values
-- /* gg(x) = x + a^genstart*/
-- gg[0] = 1;
-- gg[1] = powers[genstart];
--  The polynomial is built by multipliying gg(i-1)(x) by (x + a^(genstart + i))
--
-- alpha = powers[genstart+1];
--
-- for (j = 0; j<(iterate-1); j++)
--	 {
--	  for (p = 1; p<=(j+2); p++)
--		  {
--			ggmul[p] = gfmul(gg[p-1],alpha);
--		  }
--	  for (p = 1; p<=(j+2); p++)
--		  {
--			gg[p] = gg[p] ^ ggmul[p];
--		  }
--	  alpha = gfmul(alpha,2);
--	 }
--
----- end genvar
--
--	 for (k = 0; k<40; k++)
--	  {
--		alphamatrix[r-h][k] = gg[k+1];
--	  }
--
--	}
--	for (j = 0; j<r; j++)
--	 {
--	  fprintf(rom,"TABLE\n");
--	  fprintf(rom,"romadd[] => alpha[];\n");
--
--		 for (k = 0; k<(r-1); k++)
--		  {
--			fprintf(rom,"%d => %d;\n",r-k,alphamatrix[k][j]);
--		  }
--
--	  fprintf(rom,"END TABLE;\n\n");
--
--	 }
----------------

end gen_all_pol_coefs;


function gen_num_bit_errors(m : NATURAL) return std_logic_matrix is
	
	constant two_pow_m		: NATURAL := 2**m;
	Constant log2m        : NATURAL := log2_ceil_table(m+1);    

	variable tmp : Std_Logic_Vector(m downto 1);
	variable tmp2 : Std_Logic_Vector(log2m downto 1);
	variable tmp3 : Std_Logic_Vector(m+log2m downto 1);

	variable tmp_nat, count_bits : NATURAL;

	variable num_bit_err_matrix : std_logic_matrix(two_pow_m downto 1, m+log2m downto 1);

begin

  for H in 1 to two_pow_m loop
		tmp_nat := H-1;
		count_bits := 0;
		for J in 1 to m loop
			if tmp_nat mod 2 = 1 then
				count_bits := count_bits + 1;
			end if;
			tmp_nat := tmp_nat / 2;
		end loop;
		tmp := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => H-1, SIZE => m), SIZE => m);
		--natural_2_m(arg => H-1, size => m);
		tmp2 := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => count_bits, SIZE => log2m), SIZE => log2m); 
		--natural_2_m(arg => count_bits, size => log2m);
		tmp3 := tmp&tmp2;
		for I in 1 to m+log2m loop
			num_bit_err_matrix(H, I) := tmp3(I);
		end loop;
	end loop;

return num_bit_err_matrix;

end gen_num_bit_errors;



procedure pla_table(signal invec: in std_logic_vector;
										signal outvec: out std_logic_vector;
										constant table: std_logic_matrix) is
	variable x : std_logic_vector (table'range(1)); -- product lines
	variable y : std_logic_vector (outvec'range); -- outputs
	variable b : std_logic;
begin
	assert (invec'length + outvec'length = table'length(2))
		report "Size of Inputs and Outputs do not match table size"
		severity ERROR;


-- Calculate the AND plane
x := (others=>'1');
for i in table'range(1) loop
	for j in invec'range loop
  	b := table (i,table'left(2)-invec'left+j);
		if (b='1') then
    	x(i) := x(i) AND invec (j);
		elsif (b='0') then
			x(i) := x(i) AND NOT invec(j);
		end if;
-- If b is not ’0’ or ’1’ (e.g. ’-’) product line is insensitive to invec(j)
	end loop;
end loop;
-- Calculate the OR plane
y := (others=>'0');
for i in table'range(1) loop
	for j in outvec'range loop
		b := table(i,table'right(2)-outvec'right+j);
		if (b='1') then
			y(j) := y(j) OR x(i);
		end if;
	end loop;
end loop;
outvec <= y;

end pla_table;

-------------------

function generate_roots (m, check, genstart, rootspace : NATURAL;
												 Index_of, alpha_to_power: NATURAL_ARRAY) return NATURAL_ARRAY is
	variable roots: NATURAL_ARRAY(check downto 1);
	variable alpha, alpha_step : NATURAL;
	Constant gf_n_max : NATURAL := 2**m-1;


	begin
		alpha_step := alpha_to_power(rootspace);
		roots(1) := alpha_to_power((genstart*rootspace) mod gf_n_max);
		alpha    := alpha_to_power((genstart*rootspace) mod gf_n_max);
		for J in 2 to check loop
			alpha := GFmul(alpha, alpha_step, Index_of, alpha_to_power);
			roots(J) := alpha;
		

		end loop;	

return roots;

end generate_roots;


function make_chain (size, m, rootspace: NATURAL;
										 Index_of, alpha_to_power: NATURAL_ARRAY)
										 return NATURAL_ARRAY is
	variable negroots : NATURAL_ARRAY(size downto 0);
	variable alpha, tmp: NATURAL;
	variable index_of_A, index_of_B, prod : NATURAL;
	Constant gf_n_max : NATURAL := 2**m-1;

	begin
		for J in 0 to size loop
			--alpha := alpha_to_power(J);  -- without rootspace parameter
			alpha := alpha_to_power((rootspace*J) mod gf_n_max);
			index_of_A := Index_of(alpha);
			if alpha=0 then
				tmp := 0;
			else
				innerloop: for L in 1 to 2**m-1 loop
				-- INLINING on GFMul function 
				-- this is recommended solution for SPR 178783
					index_of_B := Index_of(L);
					--prod := (index_of_A + index_of_B) mod (Index_of'HIGH);
					prod := (index_of_A + index_of_B) mod gf_n_max;
					tmp := alpha_to_power(prod);
				--tmp := GFmul(alpha, NATURAL'(L), Index_of, alpha_to_power);
					if tmp = 1 then
						negroots(J) := L;
						exit innerloop;
					end if;
				end loop innerloop;
			end if;
		end loop;
		return negroots;

----- with the rootspace (rootspace) parameter
--void makechn ()
--{
--
--int j,l,alpha;
--int gfmax = (int)pow(2,mm)-1;
--
--for (j = 0; j<41; j++)
--	{
--//	 alpha = powers[j];  // without the rootspace parameter
--	 alpha = powers[(rootspace*j)%gfmax];
--	 for (l = 1; l<pow(2,mm); l++)
--		 {
--		  if (gfmul(alpha,l) == 1)
--			 {
--			  printf("negroot%d = %d\n",j,l);
--			 }
--		 }
--	 }
--}


end make_chain;


function make_cont  (size, m, check, rootspace: NATURAL;
										 Index_of, alpha_to_power: NATURAL_ARRAY)
										 return NATURAL_ARRAY is
	variable controots : NATURAL_ARRAY(size downto 0);
	variable alpha, tmp, alphapow: NATURAL;
	Constant gf_n_max : NATURAL := 2**m-1;

	begin
		for J in 0 to size loop
			--alpha := alpha_to_power(J);  -- without rootspace parameter
			alpha := alpha_to_power((rootspace*J) mod gf_n_max);
			for L in 1 to 2**m-1 loop
				tmp := GFmul(alpha, NATURAL'(L), Index_of, alpha_to_power);
				if tmp = 1 then
					alphapow := L;
					for K in 1 to check-1 loop
						alphapow := GFmul(alphapow, NATURAL'(L), Index_of, alpha_to_power);
					end loop;
					controots(J) := alphapow;
				end if;
			end loop;
		end loop;
		return controots;


----- with the rootspace (rootspace) parameter
--void makecont ()
--{
--
--int j,l,cr,alpha,alphapow;
--
--for (j = 0; j<21; j++)
--	{
--	 alpha = powers[j];
--	 for (l = 1; l<pow(2,mm); l++)
--		 {
--		  if (gfmul(alpha,l) == 1)
--			 {
--			  alphapow = l;
--			  for (cr=1; cr<r ; cr++)
--			  {
--				alphapow = gfmul(alphapow,l);
--			  }
--			  fprintf(rsd,"constant controot%d = %d ;\n",j,alphapow);
--			 }
--		 }
--	 }
--}


end make_cont;

-- oh no!! this function is using n, need to analyze why ... Otherwise I am a bit screwed up!!
	-- this constants are obsoleted and not used since I did some long time past enhancement 
	--I don't need this constant any more  therefore I don;t need this function
-- function make_cont_exp  (size, m, n, rootspace: NATURAL;
										 -- Index_of, alpha_to_power: NATURAL_ARRAY)
										 -- return NATURAL_ARRAY is
	-- variable controots : NATURAL_ARRAY(size downto 0);
	-- variable alpha, tmp, alphapow: NATURAL;
	-- Constant gf_n_max : NATURAL := 2**m-1;
-- 
	-- begin
		-- for J in 0 to size loop
			-- alpha := alpha_to_power((rootspace*J) mod gf_n_max);
			-- for L in 1 to 2**m-1 loop
				-- tmp := GFmul(alpha, NATURAL'(L), Index_of, alpha_to_power);
				-- if tmp = 1 then
					-- alphapow := L;
					-- for K in 1 to n/2 loop  --check-1 loop
						-- alphapow := GFmul(alphapow, NATURAL'(L), Index_of, alpha_to_power);
					-- end loop;
					-- controots(J) := alphapow;
				-- end if;
			-- end loop;
		-- end loop;
		-- return controots;
-- 
-- end make_cont_exp;

function Get_max_of_three(param_1, param_2, param_3 : NATURAL) return NATURAL is

  variable max : NATURAL;

begin

	max := param_1;
	if param_2 > max then
		max := param_2;
	end if;
	if param_3 > max then
		max := param_3;
	end if;
	return max;

end Get_max_of_three;

function Build_binary_table(n : NATURAL) return std_logic_matrix is

	Constant log_size : NATURAL := LOG2_ceil_table(n+1);
	variable binary_table : std_logic_matrix(0 to n, log_size downto 1);
	variable tmp : std_logic_vector(log_size downto 1);

begin

for I in 0 to n loop
	tmp := CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => I, SIZE => log_size), SIZE => log_size);
	for J in log_size downto 1 loop
		binary_table(I, J) := tmp(J);
	end loop;
end loop;
return binary_table;

end function Build_binary_table;


function calc_errs(check : NATURAL; Erasures: STRING)	return NATURAL is
	variable errs : NATURAL := 1;
begin
	if Erasures="false" or Erasures="FALSE" then
		errs := check/2;
	else
		errs := check;
	end if;
	return errs;
end function calc_errs;

end auk_rs_fun_pkg;

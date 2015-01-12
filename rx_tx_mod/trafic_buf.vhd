library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity trafic_buf is
	 port(
		 reset: in std_logic;

		 time_of_fake_translation: in std_logic_vector(23 downto 0);
		 tangenta: in std_logic; --# if it '0' we cut trafic. Stop work RF transiver 

		 clk_phy: in std_logic;
		 i_rx_dv : in STD_LOGIC;
		 i_rxd : in STD_LOGIC_VECTOR(7 downto 0);

		 clk_phyq: in std_logic;  --# clk_phyq >= clk_phy 
		 o_rx_dv : out STD_LOGIC;
		 o_rxd : out STD_LOGIC_VECTOR(7 downto 0)
	     );
end trafic_buf;


architecture trafic_buf of trafic_buf is

component frame_fifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		rdusedw		: OUT STD_LOGIC_VECTOR (13 DOWNTO 0);
		wrfull		: OUT STD_LOGIC 
	);
end component;


type Tstm is (WAITING,READ_FRAME,STOPING,STARTING);
signal stm:Tstm;

signal s_rx_dv,swr,wr,srd,rd,empty,full : std_logic;
signal s_rxd : std_logic_vector(7 downto 0);

type Tmdelay is array(2 downto 0) of std_logic_vector(8 downto 0);
signal mdelay:Tmdelay:=(others=>(others=>'0'));

signal wr_data,fifosed : std_logic_vector(8 downto 0);
signal rdusedw : std_logic_vector(13 downto 0);

signal start_time_cnt:std_logic_vector(time_of_fake_translation'Length-1 downto 0);


begin

process (clk_phy) is
begin		
	if rising_edge(clk_phy) then
		if reset='1' then
			swr<='0';
		else --# reset
			mdelay(0)<=i_rx_dv&i_rxd;
			for i in 2 downto 1 loop
				mdelay(i)<=mdelay(i-1);
			end loop;
			
			if mdelay(0)(8)='0' and mdelay(1)(8)='0' and mdelay(2)(8)='0' then
				swr<='0';
				wr_data<='0'&x"00";
			else
				swr<='1';
				wr_data<=mdelay(2);
			end if;	

		end if; --# reset
	end if;
end process;

 	

process (clk_phyq) is
begin		
	if rising_edge(clk_phyq) then

		if reset='1' then
			stm<=WAITING;
			srd<='0';
		else --# reset
			case stm is
			when WAITING=>
				if tangenta='0' then
					stm<=STOPING;
					srd<='0';
				else
					if unsigned(rdusedw)>=2048 then
						stm<=READ_FRAME;
						srd<='1';
					else
						srd<='0';
					end if;
				end if;

			when READ_FRAME=>
				if fifosed(8)='0' then
					stm<=WAITING;
				end if;
				srd<='1';
                s_rx_dv<=fifosed(8);
                s_rxd<=fifosed(7 downto 0);
			when STOPING=>
				srd<='0';
				s_rx_dv<='0';
				s_rxd<=x"00";
				if tangenta='1' then
					stm<=STARTING;
				end if;
				start_time_cnt<=time_of_fake_translation;
			when STARTING=>
				if tangenta='1' then
					if unsigned(start_time_cnt)>0 then
						start_time_cnt<=start_time_cnt-1;
					else
						stm<=WAITING;
					end if;
				else
					stm<=STOPING;
				end if;
				s_rx_dv<='0';
				s_rxd<=x"00";

			end case;
		end if; --# reset

		o_rx_dv<=s_rx_dv;
		o_rxd<=s_rxd;

	end if;
end process;	
	

wr<=swr and not (full);
rd<=srd and not (empty);



frame_fifo_i: frame_fifo 
	PORT map
	(
		aclr=>reset,
		data =>wr_data,
		rdclk =>clk_phyq,
		rdreq =>rd,
		wrclk =>clk_phy,
		wrreq =>swr,
		q	=>fifosed,
		rdempty	=>empty,
		rdusedw	=>rdusedw,
		wrfull	=>full
	);



end trafic_buf;

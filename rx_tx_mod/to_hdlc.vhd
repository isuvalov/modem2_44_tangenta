library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity to_hdlc is
	generic(
		DIV_POW_2:natural:=5
	);
	port(
		clk : in STD_LOGIC;		
		reset : in std_logic;
		
		read_irq: in std_logic; --# провод запроса на подачу spi клока
		spi_clk: out std_logic;
		spi_ce: out std_logic;  --# '1' is valid
		spi_data: in std_logic;
		
		fifo_full: out std_logic;

		hdlc_stream_rd: in std_logic;
		hdlc_stream: out std_logic
		);
end to_hdlc;



architecture to_hdlc of to_hdlc is

component fifo256x2
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		rdusedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
end component;


signal have_data_in_fifo,spi_ce_w1:std_logic;
signal cnt_in_frame,cnt_out_frame,d_cnt_frame,cnt_in_frame_byclk:std_logic_vector(7 downto 0);


type Twrstm is (STARTING,STARTING2,WORKING);
signal wrstm:Twrstm;

type Tstm is (WAITING,START_READ,READ,SHIFT_7E_6BIT,FIN);
signal stm:Tstm;

signal fifo_rd:std_logic;
signal reg:std_logic_vector(7 downto 0);
--# В fifo записываются и данные и энейбл, данные младший бит
signal data_from_fifo,data_from_fifo_reg:std_logic_vector(1 downto 0);
signal bit_cnt:std_logic_vector(2 downto 0);

signal have_data_inreg:std_logic;
signal fifo_empty:std_logic;
signal sm_cnt:std_logic_vector(2 downto 0);

constant C_7E:std_logic_vector(7 downto 0):=x"7E";

signal tofifo:std_logic_vector(1 downto 0);
signal fifo_wr,fifo_wr_w1,empty,frame_rd:std_logic;
signal rdusedw		: STD_LOGIC_VECTOR (7 DOWNTO 0);

signal was_empty,fifo_wr_byclk,fifo_wr_byclk_w1,can_read_fifo:std_logic;

signal spi_div_cnt: std_logic_vector(DIV_POW_2-3 downto 0):=(others=>'0');
signal read_irq_byclk,read_irq_byclk_w1:std_logic;

type Tspi_stm is (WAITING,START_READ,FIN);
signal spi_stm:Tspi_stm;
signal s_spi_clk:std_logic;
signal bytecnt:std_logic_vector(3 downto 0);


begin


spi_clk<=s_spi_clk;
process(clk) is
begin
	if rising_edge(clk) then		
		read_irq_byclk<=read_irq;
		read_irq_byclk_w1<=read_irq_byclk;
		if reset='1' then
			spi_stm<=WAITING;
			fifo_wr<='0';
			s_spi_clk<='0';
			cnt_in_frame<=(others=>'0');
		else
			case spi_stm is
			when WAITING=>
				if read_irq_byclk_w1='0' and read_irq_byclk='1' then
					spi_stm<=START_READ;
				end if;
				spi_div_cnt<=(others=>'1');
				s_spi_clk<='0';
				bytecnt<=(others=>'0');
				fifo_wr<='0';
				spi_ce<='0';
			when START_READ=>
				spi_ce<='1';
				spi_div_cnt<=spi_div_cnt+1;
				if spi_div_cnt(spi_div_cnt'Length-2 downto 0)=0 then
					s_spi_clk<=not s_spi_clk;
					if unsigned(bytecnt)<2*8-1 then
						bytecnt<=bytecnt+1;
					else
						spi_stm<=FIN;
					end if;
				end if;

				if spi_div_cnt='1'&EXT("0",spi_div_cnt'Length-1) then
					fifo_wr<='1';
				else
					fifo_wr<='0';	
				end if;
				tofifo<='1'&spi_data;
			when FIN=>
				spi_ce<='0';
				tofifo<="00";
				fifo_wr<='1';
				cnt_in_frame<=cnt_in_frame+1;
				spi_stm<=WAITING;
			when others=>
			end case;
		end if;
	end if;
end process;




fifo256x2_inst : fifo256x2 PORT MAP (
		aclr	 => reset,
		data	 => tofifo,
		rdclk	 => clk,
		rdreq	 => fifo_rd,
		wrclk	 => clk,
		wrreq	 => fifo_wr,
		q	 => data_from_fifo,
		rdempty	 => empty,
		rdusedw	 => rdusedw,
		wrfull	 => fifo_full
	);
fifo_empty<=empty;

process (clk)
variable v_reg:std_logic_vector(7 downto 0);
begin		
	if rising_edge(clk) then
		if reset='1' then
			cnt_out_frame<=(others=>'0');
			
			stm<=WAITING;
			fifo_rd<='0';
			reg<=x"7E";
			bit_cnt<="000";
			have_data_inreg<='0'; --# указывает наличие данных в конвеерном регистре данных
			was_empty<='1';
			fifo_wr_byclk<='0';
			fifo_wr_byclk_w1<='0';
			can_read_fifo<='0';
		else --#reset
			fifo_wr_byclk<=fifo_wr_w1;
			fifo_wr_byclk_w1<=fifo_wr_byclk;
			if was_empty='0' and fifo_wr='0' then
				can_read_fifo<='1';
			else
				can_read_fifo<='0';
			end if;

			d_cnt_frame<=cnt_in_frame-cnt_out_frame;
			if hdlc_stream_rd='1' then
			case stm is 
				when WAITING=>
					--if hdlc_stream_rd='1' then
					if unsigned(d_cnt_frame)>0 and bit_cnt=7 and can_read_fifo='1' then
						stm<=START_READ;
						cnt_out_frame<=cnt_out_frame+1;
					end if;
					if was_empty='1' and unsigned(rdusedw)>2 then
						fifo_rd<='1';
						was_empty<='0';
					else
						fifo_rd<='0';
					end if;
					bit_cnt<=bit_cnt+1;
					if bit_cnt=0 then
						reg<=x"7E";
					else
						reg<=reg(6 downto 0)&'0';
					end if;
					--end if;
				when START_READ=>
					fifo_rd<='1';
					stm<=READ;
					reg<=x"7E";
					bit_cnt<="001";					
				when READ=>
--					if hdlc_stream_rd='1' then
					bit_cnt<=bit_cnt+1;					
					if data_from_fifo(1)='0' and have_data_inreg='0' then --or empty='1'
						stm<=FIN;
						fifo_rd<='0';
						reg<=reg(6 downto 0)&"0"; --# тут задвигается 7й бит от байта x"7E";
						have_data_inreg<='1';
						data_from_fifo_reg<=data_from_fifo;
					else
					    if reg(4 downto 0)="11111" and data_from_fifo(0)='1' and have_data_inreg='0'
--							(reg(4 downto 0)="11111" and data_from_fifo_reg(0)='1' and have_data_inreg='1')
								then
							fifo_rd<='0';
							reg<=reg(6 downto 0)&"0";
--						    reg<="00111110";
							have_data_inreg<='1';
							data_from_fifo_reg<=data_from_fifo;
						else
							fifo_rd<='1';
							if have_data_inreg='0' then
								reg<=reg(6 downto 0)&data_from_fifo(0);
							else
								reg<=reg(6 downto 0)&data_from_fifo_reg(0);
								have_data_inreg<='0';
							end if;
						end if;
					end if;
					bit_cnt<=bit_cnt+1;
--					end if; --#hdlc_stream_rd_ce
				when FIN=>
			        fifo_rd<='0';
					if empty='1' then
						was_empty<='1';
					end if;
					bit_cnt<=bit_cnt+1;
					reg<=reg(6 downto 0)&"1";  --# тут задвигается 6й бит от байта x"7E";
					if fifo_empty='1' then
						--# Необходимо не учитывать то что было считано из FIFO
						--# Т.е. не использовать data_from_fifo_reg
						--# А так-же прогрузить опустошенный конвеерное слово из FIFO 
						--# когда FIFO опять наполниться
						--have_data_inreg<='0';
						stm<=SHIFT_7E_6BIT;
					else
						--# Использовать data_from_fifo_reg
						stm<=SHIFT_7E_6BIT;
					end if;
					have_data_inreg<='0';
					sm_cnt<=(others=>'0');
				when SHIFT_7E_6BIT=>
					if hdlc_stream_rd='1' then
					bit_cnt<=bit_cnt+1;
					if unsigned(sm_cnt)<=5 then
						sm_cnt<=sm_cnt+1;
						reg<=reg(6 downto 0)&C_7E(5-conv_integer(sm_cnt));
					else
						stm<=WAITING;
						reg<=reg(6 downto 0)&'0';
					end if;
					end if;
				when others=>
			end case;
			else
				fifo_rd<='0';
			end if;
		end if; --#reset
		hdlc_stream<=reg(7);
	end if;	--clk
end process;
		 

	
end to_hdlc;

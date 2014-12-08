library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity from_hdlc is
	generic(
		DIV_POW_2:natural:=5
	);
	port(
		clk : in STD_LOGIC;		
		reset : in std_logic;
		
		write_irq: out std_logic; --# провод квитирования выставления информации в SPIный буфер
		spi_clk: out std_logic;
		spi_ce: out std_logic;  --# '1' is valid
		spi_data: out std_logic;   --# выставляю по falling edge, Т.е должно считываться по rising edge
		
		fifo_full: out std_logic;

		hdlc_stream_ce: in std_logic;
		hdlc_stream: in std_logic
		);
end from_hdlc;



architecture from_hdlc of from_hdlc is

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

signal rdusedw	: STD_LOGIC_VECTOR (7 DOWNTO 0);
signal empty	: STD_LOGIC ;


signal cnt_in_frame,cnt_out_frame,d_cnt_frame:std_logic_vector(7 downto 0);
signal reg,reg2,reg2_w2,reg2_w1,reg_w1,reg_w2,reg_bitstaf:std_logic_vector(7 downto 0);
signal data,bit_ce,frame_ce,bit_ce_w1,hdlc_stream_w1:std_logic;
signal data_from_fifo,data_from_fifo_reg:std_logic_vector(1 downto 0);

signal spi_div_cnt: std_logic_vector(DIV_POW_2-3 downto 0):=(others=>'0');

type Tspi_stm is (WAITING,START_WRITE,STOP_WRITE);
signal spi_stm:Tspi_stm;

type Tout_spi is (WAITING,START_WRITE,STOP_WRITE,TEST_BIT_D,TEST_BIT_D2,TEST_BIT,WAITING_IRQ);
signal out_spi:Tout_spi;

signal s_spi_clk,fifo_wr,fifo_rd,hdlc_stream_ce_w1,hdlc_stream_ce_w2:std_logic;
signal tofifo:std_logic_vector(1 downto 0);
signal write_irq_cnt:std_logic_vector(3 downto 0);
signal frame_ce_W:std_logic_vector(7 downto 0);


begin

spi_clk<=s_spi_clk;
process (clk)
begin		
	if rising_edge(clk) then
		if reset='1' then
			spi_stm<=WAITING;
			out_spi<=WAITING;
			fifo_wr<='0';
			fifo_rd<='0';
			s_spi_clk<='0';
			cnt_in_frame<=(others=>'0');
			cnt_out_frame<=(others=>'0');
			d_cnt_frame<=(others=>'0');
			spi_ce<='1';
			spi_div_cnt<=(others=>'0');
			hdlc_stream_ce_w1<='0';
		else
			hdlc_stream_ce_w1<=hdlc_stream_ce;
			hdlc_stream_ce_w2<=hdlc_stream_ce_w1;
			d_cnt_frame<=cnt_in_frame-cnt_out_frame;
			if hdlc_stream_ce_w1='1' then
			case spi_stm is
			when WAITING=>
				if frame_ce='1' then
					if bit_ce='1' then
						fifo_wr<='1';
						tofifo<='1'&data;
						spi_stm<=START_WRITE;
					else
						fifo_wr<='0';
					end if;					
				else
					fifo_wr<='0';
				end if;
			when START_WRITE=>
				if frame_ce='0' then
					spi_stm<=STOP_WRITE;
					fifo_wr<='1';
					tofifo<="00";
				else
					fifo_wr<=bit_ce; 
					if bit_ce='1' then
						tofifo<='1'&data;
					end if;
				end if;
			when STOP_WRITE=>
				fifo_wr<='0';
				
				spi_stm<=WAITING;
				cnt_in_frame<=cnt_in_frame+1;
			when others=>
			end case;
			else
				fifo_wr<='0';
			end if;

			
			case out_spi is
			when WAITING=>
				if unsigned(d_cnt_frame)>0 then
					out_spi<=TEST_BIT_D;--START_WRITE;					
				end if;
				spi_ce<='0';
				fifo_rd<='0';
			when TEST_BIT_D=>
				fifo_rd<='1';
				out_spi<=TEST_BIT_D2;
			when TEST_BIT_D2=>
				fifo_rd<='0';
				out_spi<=TEST_BIT;
			when START_WRITE=>
				spi_div_cnt<=spi_div_cnt+1;
				if spi_div_cnt(spi_div_cnt'Length-2 downto 0)=0 then
					s_spi_clk<=not s_spi_clk;
				end if;

				if spi_div_cnt='1'&EXT("0",spi_div_cnt'Length-1) then
					out_spi<=TEST_BIT_D;
				end if;
--				if spi_div_cnt='1'&EXT("0",spi_div_cnt'Length-1) then --# here point falling_edge/rising_edge
--					fifo_rd<='1';
--				else
--					fifo_rd<='0';	
--				end if;


--				out_spi<=TEST_BIT;
				spi_ce<='1';
			when TEST_BIT=>
				spi_div_cnt<=spi_div_cnt+1;
--				s_spi_clk<=not s_spi_clk;
				--spi_div_cnt<=spi_div_cnt+1;
				if data_from_fifo/="00" then
					spi_data<=data_from_fifo(0);
					out_spi<=START_WRITE;
				else
					out_spi<=STOP_WRITE;
				end if;	
				fifo_rd<='0';
			when STOP_WRITE=>
				cnt_out_frame<=cnt_out_frame+1;
				spi_ce<='0';
				write_irq<='1';
				write_irq_cnt<=(others=>'1');
				out_spi<=WAITING_IRQ;
			when WAITING_IRQ=>
				s_spi_clk<='0';
				if unsigned(write_irq_cnt)>0 then
					write_irq_cnt<=write_irq_cnt-1;
					write_irq<='1';
				else
					write_irq<='0';
					out_spi<=WAITING;
				end if;
				
			when others=>
			end case;

		end if; --# reset
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
		rdempty	 => open,
		rdusedw	 => rdusedw,
		wrfull	 => fifo_full
	);

process (clk)
begin		
	if rising_edge(clk) then
		if reset='1' then
			reg<=x"00";
			reg2<=x"00";
			reg_bitstaf<=(others=>'0');
			frame_ce_W<=(others=>'0');
			frame_ce<='0';
			hdlc_stream_w1<='0';
			bit_ce<='0';
		else --#reset
			if hdlc_stream_ce='1' then
				hdlc_stream_w1<=hdlc_stream;
				if reg2(5 downto 0)/="011111" then
					reg_bitstaf<=reg_bitstaf(6 downto 0)&hdlc_stream;
				end if;
				reg<=reg(6 downto 0)&hdlc_stream;
				reg2<=reg2(6 downto 0)&reg(7);
				reg_w1<=reg;
				reg_w2<=reg_w1;
				reg2_w1<=reg2_w2;
				reg2_w2<=reg2_w1;
        	    bit_ce_w1<=bit_ce;
				if bit_ce='1' then
					frame_ce_W<=frame_ce_W(frame_ce_W'Length-2 downto 0)&frame_ce;
				end if;

	            data<=reg(7);
				if reg2(5 downto 0)="011111" then
					bit_ce<='0';
				else
					if reg2=x"7E" and reg/=x"7E" and reg_bitstaf/=x"7E" then
						if frame_ce_W(frame_ce_W'Length-1)='0' then
							frame_ce<='1';					
						end if;
						bit_ce<='1';
					elsif reg=x"7E" and reg2/=x"7E" then
						frame_ce<='0';									
						bit_ce<='1';
					else
						bit_ce<='1';
					end if;				
				end if;
			end if;
		end if; --#reset
	end if;	--clk
end process;
		 

	
end from_hdlc;

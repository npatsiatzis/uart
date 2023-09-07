// Verilator Example
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <memory>
#include <set>
#include <deque>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>
#include "Vuart_top.h"
#include "Vuart_top_uart_top.h"   //to get parameter values, after they've been made visible in SV


#define MAX_SIM_TIME 300
#define VERIF_START_TIME 7
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

// input interface transaction item class
class InTx {
    private:
    public:
        uint32_t i_data;
};


// output interface transaction item class
class OutTx {
    public:
        uint32_t o_data;
};

//in domain Coverage
class InCoverage{
    private:
        std::set <uint32_t> in_cvg;
    
    public:
        void write_coverage(InTx *tx){
            // std::tuple<uint32_t,uint32_t> t;
            // t = std::make_tuple(tx->A,tx->B);
            // in_cvg.insert(t);
            in_cvg.insert(tx->i_data);
        }

        bool is_covered(uint32_t data){
            // std::tuple<uint32_t,uint32_t> t;
            // t = std::make_tuple(A,B);            
            // return in_cvg.find(t) == in_cvg.end();
            return in_cvg.find(data) == in_cvg.end();
        }
};

//out domain Coverage
class OutCoverage {
    private:
        std::set <uint32_t> coverage;
        int cvg_size = 0;

    public:
        void write_coverage(OutTx* tx){
            coverage.insert(tx->o_data); 
            cvg_size++;
        }

        bool is_full_coverage(){
            // std::cout << "OUT COVERAGE size = " << coverage.size() << std::endl;
            // std::cout << "OUT COVERAGE = " << cvg_size << std::endl;
            return cvg_size == (2 << (Vuart_top_uart_top::g_word_width-1));
        }
};


// ALU scoreboard
class Scb {
    private:
        std::deque<InTx*> in_q;
        
    public:
        // Input interface monitor port
        void writeIn(InTx *tx){
            // Push the received transaction item into a queue for later
            in_q.push_back(tx);
        }

        // Output interface monitor port
        void writeOut(OutTx* tx){
            // We should never get any data from the output interface
            // before an input gets driven to the input interface
            if(in_q.empty()){
                std::cout <<"Fatal Error in AluScb: empty InTx queue" << std::endl;
                exit(1);
            }

            // Grab the transaction item from the front of the input item queue
            InTx* in;
            in = in_q.front();
            in_q.pop_front();

            if(in->i_data != tx->o_data){
                std::cout << "Test Failure!" << std::endl;
                std::cout << "Expected : " <<  in->i_data << std::endl;
                std::cout << "Got : " << tx->o_data << std::endl;
            } else {
                std::cout << "PASS : ";
                std::cout << "Expected : " <<  in->i_data;
                std::cout << " Got : " << tx->o_data << std::endl;
            }

            // As the transaction items were allocated on the heap, it's important
            // to free the memory after they have been used
            delete in;    //input monitor transaction
            delete tx;    //output monitor transaction
        }
};

// interface driver
class InDrv {
    private:
        // Vuart_top *dut;
        std::shared_ptr<Vuart_top> dut;
        VerilatedVcdC *m_trace;
    public:
        InDrv(VerilatedVcdC *m_trace,std::shared_ptr<Vuart_top> dut){
            this->dut = dut;
            this->m_trace = m_trace;
        }

        void drive(InTx *tx){
            // we always start with in_valid set to 0, and set it to
            // 1 later only if necessary
            // dut->i_valid = 0;


            // Don't drive anything if a transaction item doesn't exist
            if(tx != NULL){
                dut->i_we = 1;
                dut->i_stb = 1;
                dut->i_addr = 0;
                dut->i_data = tx->i_data;
                // Release the memory by deleting the tx item
                // after it has been consumed

                delete tx;
            }

        }

        void drive_rest(){

            // std::cout << "data is " << dut->i_data  << std::endl;

            dut->i_clk ^= 1;
            dut->eval();
            m_trace->dump(sim_time);
            sim_time++;
            dut->i_clk ^= 1;
            dut->eval();
            m_trace->dump(sim_time);
            sim_time++;

            dut->i_we = 1;
            dut->i_stb = 0;
            dut->i_addr = 0;
            dut->i_data = 0;

            // dut->i_clk ^= 1;
            // dut->eval();
            // dut->i_clk ^= 1;
            // dut->eval();

            // std::cout << "WAITING FOR RX BUSY TO FALL" << std::endl;

            while(1) {
                dut->i_clk ^= 1;
                dut->eval();
                m_trace->dump(sim_time);
                sim_time++;
                if(dut->i_clk == 1) {
                    // std::cout << dut->o_rx_busy << "," << dut->f_rx_busy_prev << std::endl;
                    if(dut->o_rx_busy == 0 && dut->f_rx_busy_prev == 1){
                        break;
                    }
                    dut->i_we = 1;
                    dut->i_stb = 0;
                    dut->i_addr = 0;
                    dut->i_data = 0;
                }

                // std::cout << "STILL WAITING" << std::endl;
                // std::cout << "we = " << dut->i_we << " , stb = " << dut->i_stb << " , addr = " << dut->i_addr << std::endl; 
                // std::cout << "o_rx_busy = " << dut->o_rx_busy << "busy_prev is " << dut->f_rx_busy_prev << std::endl;
            }

            dut->i_we = 0;
            dut->i_stb = 1;
            dut->i_addr = 1;
            dut->i_data = 0;

            dut->i_clk ^= 1;
            dut->eval();
            m_trace->dump(sim_time);
            sim_time++;
            dut->i_clk ^= 1;
            dut->eval();
            m_trace->dump(sim_time);
            sim_time++;
        }
};

// input interface monitor
class InMon {
    private:
        // Vuart_top *dut;
        std::shared_ptr<Vuart_top> dut;
        // Scb *scb;
        std::shared_ptr<Scb>  scb;
        // InCoverage *cvg;
        std::shared_ptr<InCoverage> cvg;

    public:
        InMon(std::shared_ptr<Vuart_top> dut, std::shared_ptr<Scb>  scb, std::shared_ptr<InCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
        }

        void monitor(){
            if(dut->i_we == 1 && dut->i_stb == 1 && dut->i_addr == 0){
                InTx *tx = new InTx();
                tx->i_data = dut->i_data;
                // tx->B = dut->i_B;
                // then pass the transaction item to the scoreboard
                scb->writeIn(tx);
                cvg->write_coverage(tx);
            }
        }
};

// ALU output interface monitor
class OutMon {
    private:
        // Vuart_top *dut;
        std::shared_ptr<Vuart_top> dut;
        // Scb *scb;
        std::shared_ptr<Scb> scb;
        // OutCoverage *cvg;
        std::shared_ptr<OutCoverage> cvg;
    public:
        OutMon(std::shared_ptr<Vuart_top> dut, std::shared_ptr<Scb> scb, std::shared_ptr<OutCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
        }

        void monitor(){
            if(dut->i_we == 0 && dut->i_stb == 1 && dut->i_addr == 1){

                OutTx *tx = new OutTx();
                tx->o_data = dut->o_data;

                // then pass the transaction item to the scoreboard
                scb->writeOut(tx);
                cvg->write_coverage(tx);
            }
        }
};

//sequence (transaction generator)
// coverage-driven random transaction generator
// This will allocate memory for an InTx
// transaction item, randomise the data, until it gets
// input values that have yet to be covered and
// return a pointer to the transaction item object
class Sequence{
    private:
        InTx* in;
        // InCoverage *cvg;
        std::shared_ptr<InCoverage> cvg;
    public:
        Sequence(std::shared_ptr<InCoverage> cvg){
            this->cvg = cvg;
        }

        InTx* genTx(){
            in = new InTx();
            // std::shared_ptr<InTx> in(new InTx());
            // if(rand()%5 == 0){
            in->i_data = rand() % (1 << Vuart_top_uart_top::g_word_width);  
            // in->B = rand() % (1 << Vuart_top_uart_top::g_word_width);  

            while(cvg->is_covered(in->i_data) == false){
                in->i_data = rand() % (1 << Vuart_top_uart_top::g_word_width);  
                // in->B = rand() % (1 << Vuart_top_uart_top::g_word_width); 
            }
            return in;
            // } else {
                // return NULL;
            // }
        }
};


void dut_reset (std::shared_ptr<Vuart_top> dut, vluint64_t &sim_time){
    dut->i_rst = 0;
    if(sim_time >= 0 && sim_time < 6){
        dut->i_rst = 1;
    }
}

int main(int argc, char** argv, char** env) {
    srand (time(NULL));
    Verilated::commandArgs(argc, argv);
    // Vuart_top *dut = new Vuart_top;
    // std::shared_ptr<VerilatedContext> contextp{new VerilatedContext};
    std::shared_ptr<Vuart_top> dut(new Vuart_top);

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    InTx   *tx;

    // Here we create the driver, scoreboard, input and output monitor and coverage blocks
    std::unique_ptr<InDrv> drv(new InDrv(m_trace,dut));
    std::shared_ptr<Scb> scb(new Scb());
    std::shared_ptr<InCoverage> inCoverage(new InCoverage());
    std::shared_ptr<OutCoverage> outCoverage(new OutCoverage());
    std::unique_ptr<InMon> inMon(new InMon(dut,scb,inCoverage));
    std::unique_ptr<OutMon> outMon(new OutMon(dut,scb,outCoverage));
    std::unique_ptr<Sequence> sequence(new Sequence(inCoverage));

    while (outCoverage->is_full_coverage() == false) {
        // random reset 
        // 0-> all 0s
        // 1 -> all 1s
        // 2 -> all random
        Verilated::randReset(2);    
        dut_reset(dut, sim_time);
        dut->i_clk ^= 1;
        dut->eval();

        m_trace->dump(sim_time);
        sim_time++;

        // Do all the driving/monitoring on a positive edge
        if (dut->i_clk == 1){

            if (sim_time >= VERIF_START_TIME) {
                // Generate a randomised transaction item 
                // tx = rndInTx(inCoverage);
                tx = sequence->genTx();

                // Pass the generated transaction item in the driver
                //to convert it to pin wiggles
                //operation similar to than of a connection between
                //a sequencer and a driver in a UVM tb
                drv->drive(tx);

                // Monitor the input interface
                // also writes recovered transaction to
                // input coverage and scoreboard
                inMon->monitor();

                drv->drive_rest();

                // Monitor the output interface
                // also writes recovered result (out transaction) to
                // output coverage and scoreboard 
                outMon->monitor();
            }
        }

    }

    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
    m_trace->close();  
    exit(EXIT_SUCCESS);
}

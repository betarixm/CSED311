# Preparations
모든 클럭 수는 ED의 num_clk 기준입니다. :)
- External Device : 200 Cycle 에서 DMA start 인터럽트를 주며, 시퀀셜 로직에서 실행되기 때문에 201 사이클에서 인터럽트가 시작됩니다.
- 추가해야할 Waves
    - UUT
        - r__if__id__inst
    - NUUT
        - memory[219:208], address2, qdata2, read_m2, write_m2, write_q2
    - DMAC
        - addr, bg, br, intrpt
    - ED
        - intrpt, num_clk

# Functionality
 이전 Lab의 테스트벤치를 실행했을 때 All pass 하는 것으로 CPU의 functionality를 증명할 수 있습니다.

# Interrupts
 처음에 external device가 intrpt wire를 통해서 CPU에 DMA start 인터럽트를 주면, CPU는 하고 있던 메모리 작업까지만 실행하고 인터럽트를 실행합니다. 199 클럭에 read_m2가 켜진 상태에서 201 클럭에 인터럽트 신호가 들어왔는데, 현재 실행 중인 메모리 처리가 종료된 이후에 인터럽트를 처리하는 것으로부터 이것을 증명할 수 있습니다. 해당 인터럽트는 DMA start 인터럽트 이기 때문에 DMAC에게 데이터의 주소와 길이를 보내주고 인터럽트를 해결합니다. qdata2 와이어를 확인해보면 12 라는 수 (길이)를 보내고 있는 것을 확인할 수 있으며, address2 와이어를 확인해보면 208을 보내고 있는 것을 확인할 수 있습니다.
 이후, DMA가 종료되었을 때에는 DMAC가 CPU에게 DMA end 인터럽트를 주고, CPU가 이를 처리하는데, 이것은 DMAC의 intrpt 와이어를 통해 확인할 수 있습니다.

# DMA
 DMAC에게 정보가 전달되고 인터럽트가 종료되면 bus의 사용을 요청합니다. 이것은 DMAC의 br 와이어를 통해 확인할 수 있으며, CPU가 현재 메모리를 사용하고 있지 않다면 해당 요청을 grant 합니다. 이것은 bg 와이어를 통해 확인할 수 있으며, 특히 220 사이클에서는 DMAC로부터 버스 요청이 왔음에도 불구하고 CPU가 grant하지 않는 모습도 확인할 수 있습니다.

# Parallel Running
 r__if__id__inst의 웨이브를 확인해보면, DMA가 진행되는 중에 다른 명령어들이 실행되고 있는 것을 확인할 수 있습니다.

# 추가 구현
 추가적으로, DMA의 4 word write 사이에 1 클럭 씩 간격을 두어 DMAC가 버스를 release 하고 grab 할 수 있도록 구현하였습니다. 219 클럭을 확인해보면, DMAC가 버스를 release 동안에 CPU가 자신의 메모리 처리를 수행하고 있는 것을 확인할 수 있습니다.


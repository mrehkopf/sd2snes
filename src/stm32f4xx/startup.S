/* startup code for STM32F401
 *
 * Written 2010 by Ingo Korb for LPC175x
 * Modified 2022 by Maximilian Rehkopf
 *
 */
        .syntax unified

        .section .vectors

        .macro  except label
        .weak   \label
        .set    \label, __unhandled_exception
        .word   \label
        .endm
        
        /* Cortex M3 standard except vectors */
        .word   __stack
        .word   _start
        except  NMI_Handler
        except  HardFault_Handler
        except  MemManage_Handler
        except  BusFault_Handler
        except  UsageFault_Handler
        .word   0
        .word   0
        .word   0
        .word   0
        except  SVC_Handler
        except  DebugMon_Handler
        .word   0
        except  PendSV_Handler
        except  SysTick_Handler

        /* External interrupt vectors */
        except  WWDG_IRQHandler
        except  PVD_IRQHandler
        except  TAMP_STAMP_IRQHandler
        except  RTC_WKUP_IRQHandler
        except  FLASH_IRQHandler
        except  RCC_IRQHandler
        except  EXTI0_IRQHandler
        except  EXTI1_IRQHandler
        except  EXTI2_IRQHandler
        except  EXTI3_IRQHandler
        except  EXTI4_IRQHandler
        except  DMA1_Stream0_IRQHandler
        except  DMA1_Stream1_IRQHandler
        except  DMA1_Stream2_IRQHandler
        except  DMA1_Stream3_IRQHandler
        except  DMA1_Stream4_IRQHandler
        except  DMA1_Stream5_IRQHandler
        except  DMA1_Stream6_IRQHandler
        except  ADC_IRQHandler
        .word   0
        .word   0
        .word   0
        .word   0
        except  EXTI9_5_IRQHandler
        except  TIM1_BRK_TIM9_IRQHandler
        except  TIM1_UP_TIM10_IRQHandler
        except  TIM1_TRG_COM_TIM11_IRQHandler
        except  TIM1_CC_IRQHandler
        except  TIM2_IRQHandler
        except  TIM3_IRQHandler
        except  TIM4_IRQHandler
        except  I2C1_EV_IRQHandler
        except  I2C1_ER_IRQHandler
        except  I2C2_EV_IRQHandler
        except  I2C2_ER_IRQHandler
        except  SPI1_IRQHandler
        except  SPI2_IRQHandler
        except  USART1_IRQHandler
        except  USART2_IRQHandler
        .word   0
        except  EXTI15_10_IRQHandler
        except  RTC_Alarm_IRQHandler
        except  OTG_FS_WKUP_IRQHandler
        .word   0
        .word   0
        .word   0
        .word   0
        except  DMA1_Stream7_IRQHandler
        .word   0
        except  SDIO_IRQHandler
        except  TIM5_IRQHandler
        except  SPI3_IRQHandler
        .word   0
        .word   0
        .word   0
        .word   0
        except  DMA2_Stream0_IRQHandler
        except  DMA2_Stream1_IRQHandler
        except  DMA2_Stream2_IRQHandler
        except  DMA2_Stream3_IRQHandler
        except  DMA2_Stream4_IRQHandler
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        except  OTG_FS_IRQHandler
        except  DMA2_Stream5_IRQHandler
        except  DMA2_Stream6_IRQHandler
        except  DMA2_Stream7_IRQHandler
        except  USART6_IRQHandler
        except  I2C3_EV_IRQHandler
        except  I2C3_ER_IRQHandler
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        except  FPU_IRQHandler
        .word   0
        .word   0
        except  SPI4_IRQHandler

/*
        CRP_Level:
          0xFFFFFFFF Disabled
          0x12345678 CRP1
          0x87654321 CRP2
          0x43218765 CRP3 (Are you sure?)
*/

        .section .text

        .global _start
        .thumb_func
_start:
        /* copy data section to ram */
        ldr     r0, =__data_load_start
        ldr     r1, =__data_load_end
        ldr     r2, =__data_start
dataloop:
        ldr.w   r3, [r0], #4
        str.w   r3, [r2], #4
        cmp     r0, r1
        blo     dataloop

        /* clear bss section */
        ldr     r0, =__bss_start__
        ldr     r1, =__bss_end__
        ldr     r2, =0
bssloop:
        str.w   r2, [r0], #4
        cmp     r0, r1
        blo     bssloop

        /* start main() */
        b       main

        /* endless loop */
        .weak __unhandled_exception
        .thumb_func
__unhandled_exception:
        b       __unhandled_exception
        
        .end

module array
    implicit none
    double precision, allocatable::mi(:),th(:),ph(:),rwork(:),evl_s(:)
    integer,dimension(:),allocatable::x(:),y(:),tag(:),x_cl,y_cl,tag_cl
    complex*16,allocatable:: h(:,:),bb(:,:),work(:)
    double precision::nsum_t(1600),nn1(1600),ee1(1600),e_2(1600)
    double precision, allocatable::mi_cl(:),th_cl(:),ph_cl(:)
    doubleprecision::dos_sum_a(1600),dos_sum_b(1600),dos_sum_c(1600),dist1(1600),dist_mi_sum(1600)
end module array

module global
    implicit none
    double precision::t,ua,ub,uc,mu,m_sum,e_sum,u,esum_t,m1,ph1,th1,nsum,e,s_f,sf_A,sf_B_C
    double precision::lambda,n_a,n_b,n_c,n_a_up,n_b_up,n_c_up,n_a_dn,n_b_dn,n_c_dn,filling_cl
    integer::d,nos,ie,flag_isoc,unit_cells,sw,nms
    integer::unit_cells_cl,nos_cl,dim_cl,d_cl
endmodule global

program liebmain
    use array
    use global
    implicit none
    integer::seed,it,i,j
    double precision::temp,temp1,get_mu_s,avg_e_quant
    double precision::m_temp1,th_temp1,ph_temp1,inpt,filling,fill_inpt,e_quant,avg_e,efinal

    open(8,file='input.dat',status='unknown')

    do i=1,8
        read(8,*)inpt
        if (i.eq.1) seed=int(inpt)
        if (i.eq.2) d=int(inpt)
        if (i.eq.3) t=dble(inpt)
        if (i.eq.4) ua=dble(inpt)
        if (i.eq.5) ub=dble(inpt)
        if (i.eq.6) uc=dble(inpt)
        if (i.eq.7) nms=int(inpt)
        if (i.eq.8) fill_inpt=dble(inpt)
    end do
    close(8)
    
    unit_cells=(d/2)**2
    nos=3*unit_cells ! no of sites
    filling=fill_inpt*2*nos
      
    print*,'unit cells_____________=',unit_cells
    print*,'sites system___________=',nos
    print*,'hopping parameter______=',t
    print*,'Ua_____________________=',ua
    print*,'ub_____________________=',ub
    print*,'uc_____________________=',uc
    print*,'Monte-Carlo steps______=',nms
    print*,'filling system_________=',filling

    allocate(x(nos),y(nos),h((2*nos),(2*nos)),mi(nos),th(nos),ph(nos),tag(nos))

    call lattice_labeling  
    Temp=0.650d0

    
    do iT=1,30
        open(1000+it)   
        if(iT.le.11) Temp=Temp-0.050d0
        if ((iT.gt.11).and.(iT.lt.21)) Temp=Temp-0.010d0
        if ((iT.gt.21)) Temp=Temp-0.0010d0

        avg_e=0.0d0
        nsum_t=0.0d0
        avg_e_quant=0.0d0
        do sw=1,nms/10
            j=0
            do i=(sw*nos-nos+1),sw*nos
                j=j+1
                read(1000+it,*) Temp1,m_temp1,th_temp1,ph_temp1 
                mi(j)=m_temp1
                th(j)=th_temp1
                ph(j)=ph_temp1
            enddo

            call matgen
            call diagonalization(h,1,2*nos)
            mu=get_mu_s(filling,temp,2*nos) 
            call energy_cal(temp,e_quant,2*nos)
            efinal=esum_t
            avg_e=avg_e+efinal  
            avg_e_quant=avg_e_quant+e_quant
            call dos_m_c
            deallocate(evl_s)
        enddo

        do ie=1,1600
            write(200+it,*) ee1(ie),nsum_t(ie)/(nms/10)
            flush(200+it)  
        enddo
        write(92,*) temp,avg_e/((2*nos)*(nms/10)),avg_e_quant/((2*nos)*(nms/10))
        flush(92)
    enddo   

end program liebmain

subroutine lattice_labeling
    use global
    use array
    implicit none
    integer::ix,iy,i1,i
    i1=-2
    do iy=1,d
        do ix=1,d
            if((mod(iy,2).ne.0).and.(mod(ix,2).ne.0))then   

                i1=i1+3
                x(i1)=ix                     !A
                y(i1)=iy
                tag(i1)=1

                x(i1+1)=ix+1                 !B
                y(i1+1)=iy
                tag(i1+1)=2

                x(i1+2)=ix                   !C
                y(i1+2)=iy+1
                tag(i1+2)=3

            endif
        enddo
    enddo
    i1=0
    do i=1,nos     
        write(12,*) i,x(i),y(i),tag(i)
        flush(12)    
    enddo

endsubroutine lattice_labeling

subroutine matgen
    use array
    use global
    implicit none
    integer::l,k,xi,yi,xd,yd,a,b
    h=complex(0.0d0,0.0d0)
    do l=1,nos
        if(tag(l).eq.1) then
            xi=1
            yi=1
            xd=1
            yd=1
            if(x(l).eq.d) xi=-d+1
            if(y(l).eq.d) yi=-d+1

            if(x(l).eq.1) xd=-d+1
            if(y(l).eq.1) yd=-d+1

            do k=1,nos
                if((tag(k).eq.2).or.((tag(k).eq.3)))then        
                    if((x(k).eq.(x(l)+xi)).and.(y(k).eq.y(l)))then  
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=t;h(b,a)=t
                        h(a+1,b+1)=t;h(b+1,a+1)=t
                    endif

                    if((x(k).eq.(x(l)-xd)).and.(y(k).eq.y(l)))then  
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=t;h(b,a)=t
                        h(a+1,b+1)=t;h(b+1,a+1)=t
                    endif
        
                    if((x(k).eq.x(l)).and.(y(k).eq.(y(l)+yi)))then  
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=t;h(b,a)=t
                        h(a+1,b+1)=t;h(b+1,a+1)=t
                    endif
        
                    if((x(k).eq.x(l)).and.(y(k).eq.(y(l)-yd)))then  
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=t;h(b,a)=t
                        h(a+1,b+1)=t;h(b+1,a+1)=t
                    endif
    
                endif
            enddo
        endif
    enddo
    call matgen_mcmf_u
    do l=1,2*nos
        do k=1,2*nos
            !if(h(l,k).ne.0) write(34,*) l,k,h(l,k)
            if(h(l,k).ne.conjg(h(k,l))) print*,l,k,'not hermitian'
        enddo
    enddo 

endsubroutine matgen

subroutine matgen_mcmf_u
    use array
    use global
    use mtmod
    implicit none
    integer::l,a,b

    m_sum=0.0d0

    do l=1,nos
        if(tag(l).eq.1) u=ua
        if(tag(l).eq.2) u=ub
        if(tag(l).eq.3) u=uc

        a=2*l-1
        b=2*l-1
        h(a,b)=(u/2.0d0)*(-mi(l)*cos(th(l)))
        h(a,b+1)=(-u/2.0d0)*mi(l)*sin(th(l))*complex(cos(ph(l)),-sin(ph(l)))
        h(a+1,b)=conjg(h(a,b+1))
        h(a+1,b+1)=(u/2.0d0)*(-mi(l)*(-cos(th(l))))

        m_sum=m_sum+((mi(l))**2.0d0)*(U/4.0d0)
    enddo

endsubroutine matgen_mcmf_u


subroutine matgen_so
    use global
    use array
    implicit none
    integer::l,a,b,k,xi,yi,xd,yd

    do l=1,nos
        if(tag(l).eq.2)then
            xi=1
            yi=1
            xd=1
            yd=1
            if(x(l).eq.d) xi=-d+1
            if(y(l).eq.d) yi=-d+1

            if(x(l).eq.1) xd=-d+1
            if(y(l).eq.1) yd=-d+1
            do k=1,nos
                if((tag(k).eq.3))then

                    if((x(k).eq.(x(l)+xi)).and.(y(k).eq.(y(l)+yi)))then 
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=-lambda*cmplx(0,1);h(b,a)=conjg(h(a,b))
                        h(a+1,b+1)=lambda*cmplx(0,1);h(b+1,a+1)=conjg(h(a+1,b+1))
                    endif

                    if((x(k).eq.(x(l)-xd)).and.(y(k).eq.(y(l)+yi)))then 
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=lambda*cmplx(0,1);h(b,a)=conjg(h(a,b))
                        h(a+1,b+1)=-lambda*cmplx(0,1);h(b+1,a+1)=conjg(h(a+1,b+1))

                    endif 

                    if((x(k).eq.(x(l)-xd)).and.(y(k).eq.(y(l)-yd)))then 
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=-lambda*cmplx(0,1);h(b,a)=conjg(h(a,b))
                        h(a+1,b+1)=lambda*cmplx(0,1);h(b+1,a+1)=conjg(h(a+1,b+1))
                    endif 

                    if((x(k).eq.(x(l)+xi)).and.(y(k).eq.(y(l)-yd)))then 
                        a=2*l-1
                        b=2*k-1
                        h(a,b)=lambda*cmplx(0,1);h(b,a)=conjg(h(a,b))
                        h(a+1,b+1)=-lambda*cmplx(0,1);h(b+1,a+1)=conjg(h(a+1,b+1))

                    endif   

                endif
            enddo
        endif
    enddo
endsubroutine matgen_so



subroutine diagonalization(h_temp,flag_diag,dim_1)
    use array
    use global
    implicit none
    integer::lda,lwmax,info,lwork,flag_diag,dim_1
    complex*16::h_temp(dim_1,dim_1)

    allocate(rwork(3*(dim_1)-2),work(2*(dim_1)-1),evl_s(dim_1))
    lda=(dim_1)
    lwmax=(dim_1)
    lwork=(2*(dim_1)-1)
    evl_s=0.0d0

    if(flag_diag==1)then
       call zheev('n','u',dim_1,h_temp,lda,evl_s,work,lwork,rwork,info)
    endif

    if(flag_diag==2)then
       call zheev('v','u',dim_1,h_temp,lda,evl_s,work,lwork,rwork,info)
    endif

    if(info.ne.0)then
        print*,'algorithm failed'  
    endif 
   
    ! do i=1,dim_1
    !     write(726,*) i, evl_s(i)
    ! enddo
    ! stop
    deallocate(rwork,work)  
endsubroutine diagonalization

double precision function get_mu_s(fill,temp2,dim_1)
    use array
    use global
    implicit none
    double precision::f,fL2,fR,mR,mL,m_d,temp2,fill
    integer::dim_1,i
    !integer::fill

    mR = maxval(evl_s)       !right-side chemical potential
    fr=0.0d0
    do i=1,dim_1
        fr=fr+(1.0d0/(exp((evl_s(i)-mR)/Temp2)+1.0d0))
    end do
    mL = minval(evl_s)       !left-side chemical potential
    fL2=0.0d0
    do i=1,dim_1
        fL2=fL2+(1.0d0/(exp((evl_s(i)-mL)/Temp2)+1.0d0))
    end do
    m_d = 0.5d0*(mL+mR)    !middle chemical potential
    f=0.0d0
    do i=1,dim_1
        f=f+(1.0d0/(exp((evl_s(i)-m_d)/Temp2)+1.0d0))
    end do
    !print*,f,fill
    do while(abs(f-fill).ge.1e-8)
        m_d = 0.5d0*(mL+mR)
        f=0.0d0
        do i=1,dim_1
            f=f+(1.0d0/(exp((evl_s(i)-m_d)/Temp2)+1.0d0))
        end do
        if(f.gt.fill)then
            !if middle filling is above target, make it the new right bound.
            mR = m_d
            fR = f
        elseif(f.lt.fill)then
            !if middle filling is below target, make it the new left bound.
            mL = m_d
            fR = f
        endif
    enddo

    !Return the middle value
    get_mu_s = m_d
    return
end function get_mu_s

subroutine energy_cal(temp2,esum,dim_1)
    use array
    use global
    implicit none
    doubleprecision::esum,temp2
    integer::n1,i,dim_1
    esum=0.0d0
    n1=0
    do i=1,dim_1
        esum=esum+(evl_s(i)/(1.0d0+(exp((evl_s(i)-mu)/temp2))))
    enddo

    esum_t=esum+m_sum
  
endsubroutine energy_cal

subroutine dos_m_c
    use array
    use global
    implicit none
    double precision::pi,eta,wmin,wmax,dw,w
    integer::nwp,j
    
    pi=4.0*atan(1.0)
    wmin=-14
    wmax=14
    nwp=1600
    dw=abs(wmax-wmin)/nwp
    w=wmin
    eta=0.050d0
    do ie=1,nwp!no of pointss bw bandwitdh of e
        w=w+dw
        nsum=0.0d0
        do j=1,2*nos
          nsum=nsum+((eta/pi)/((w-(evl_s(j)-mu))**2+((eta)**2)))
        enddo
        nsum_t(ie)=nsum_t(ie)+(nsum/(2*nos))
        if(sw.eq.(nms/10)) ee1(ie)=w
    enddo
       
endsubroutine dos_m_c

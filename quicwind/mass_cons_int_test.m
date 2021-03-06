function err=mass_cons_int_test
disp('mass_cons_int_test - testing mass consistent approximation')
n=[20,30,5];
h = rand(1,3);
w = rand(1,3);
lambda0=zeros(n);
u0= grad3z(rand(n),'zero at bottom');
[u,err] = mass_cons_int(u0,h,w,'check'); 
end
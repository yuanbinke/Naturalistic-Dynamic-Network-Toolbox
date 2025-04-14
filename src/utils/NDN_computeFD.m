function [FD] = NDN_ComputeFD(motfile_name)

  Mot = importdata(motfile_name);
  Mot = Mot(:,1:6);

  % Converts the rotational components into [mm]
  Mot(:,4:6) = 50*Mot(:,4:6);

  % Computes FD
  FD = sum(abs([0 0 0 0 0 0; diff(Mot)]),2);

end
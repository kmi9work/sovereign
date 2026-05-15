import { Position, ActionType } from '../services/api';

export type RootStackParamList = {
  CountrySelect: undefined;
  MainMenu: { countryId: number; countryName: string };
  PositionSelect: { countryId: number; countryName: string };
  ActionTypeList: {
    countryId: number;
    countryName: string;
    position: Position;
  };
  ActionForm: {
    countryId: number;
    countryName: string;
    actionType: ActionType;
    positionId: number;
  };
  CompletedActions: { countryId: number; countryName: string };
};

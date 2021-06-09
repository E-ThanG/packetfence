import { computed, toRefs } from '@vue/composition-api'
import i18n from '@/utils/locale'

export const useItemProps = {
  id: {
    type: String
  }
}

export const useItemTitle = (props) => {
  const {
    id
  } = toRefs(props)
  return computed(() => i18n.t('Revoked Certificate <code>{id}</code>', { id: id.value }))
}

export { useRouter } from '../_router'

export const useStore = (props, context) => {
  const {
    id
  } = toRefs(props)
  const { root: { $store } = {} } = context
  return {
    isLoading: computed(() => $store.getters['$_pkis/isLoading']),
    getItem: () => $store.dispatch('$_pkis/getRevokedCert', id.value)
      .catch(e => { if (e.name !== "NavigationDuplicated") throw e })
  }
}

import { pfSearchConditionType as conditionType } from '@/globals/pfSearch'
import makeSearch from '@/views/Configuration/_store/factory/search'
import api from '../_api'
export const useSearch = makeSearch('pkiRevokedCerts', {
  api,
  columns: [
    {
      key: 'selected',
      thStyle: 'width: 40px;', tdClass: 'p-0',
      locked: true
    },
    {
      key: 'ID',
      label: 'Identifier', // i18n defer
      required: true,
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'ca_id',
      required: true
    },
    {
      key: 'ca_name',
      label: 'Certificate Authority', // i18n defer
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'profile_id',
      required: true
    },
    {
      key: 'profile_name',
      label: 'Template', // i18n defer
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'cn',
      label: 'Common Name', // i18n defer
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'mail',
      label: 'Email', // i18n defer
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'valid_until',
      label: 'Valid Until', // i18n defer
      sortable: true,
      visible: true
    },
    {
      key: 'crl_reason',
      label: 'Reason', // i18n defer
      sortable: true,
      visible: true
    },
    {
      key: 'buttons',
      class: 'text-right p-0',
      locked: true
    }
  ],
  fields: [
    {
      value: 'ID',
      text: i18n.t('Identifier'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'ca_id',
      text: i18n.t('Certificate Authority Identifier'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'ca_name',
      text: i18n.t('Certificate Authority Name'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'profile_id',
      text: i18n.t('Template Identifier'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'profile_name',
      text: i18n.t('Template Name'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'cn',
      text: i18n.t('Common Name'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'mail',
      text: i18n.t('Email'),
      types: [conditionType.SUBSTRING]
    }
  ],
  sortBy: 'id',
  defaultCondition: () => ({ op: 'and', values: [
    { op: 'or', values: [
      { field: 'ID', op: 'contains', value: null },
      { field: 'ca_name', op: 'contains', value: null },
      { field: 'profile_name', op: 'contains', value: null },
      { field: 'cn', op: 'contains', value: null },
      { field: 'mail', op: 'contains', value: null }
    ] }
  ] })
})
